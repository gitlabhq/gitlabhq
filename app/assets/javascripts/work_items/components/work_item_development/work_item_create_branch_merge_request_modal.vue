<script>
import { GlForm, GlFormInputGroup, GlFormGroup, GlModal } from '@gitlab/ui';
import { debounce } from 'lodash';
import axios from '~/lib/utils/axios_utils';
import { createAlert } from '~/alert';
import { REF_TYPE_BRANCHES, REF_TYPE_TAGS } from '~/ref/constants';
import { NAME_TO_TEXT_LOWERCASE_MAP } from '~/work_items/constants';
import { visitUrl } from '~/lib/utils/url_utility';
import { createBranchMRApiPathHelper } from '~/work_items/utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import {
  findInvalidBranchNameCharacters,
  humanizeBranchValidationErrors,
} from '~/lib/utils/text_utility';
import SimpleCopyButton from '~/vue_shared/components/simple_copy_button.vue';
import RefSelector from '~/ref/components/ref_selector.vue';
import getProjectRootRef from '~/work_items/graphql/get_project_root_ref.query.graphql';
import { s__, __, sprintf } from '~/locale';
import confidentialMergeRequestState from '~/confidential_merge_request/state';
import ProjectFormGroup from '~/confidential_merge_request/components/project_form_group.vue';

export default {
  components: {
    GlForm,
    GlFormInputGroup,
    GlFormGroup,
    GlModal,
    ProjectFormGroup,
    SimpleCopyButton,
    RefSelector,
  },
  i18n: {
    sourceBranchOrTagLabel: __('Source (branch or tag)'),
    targetBranchLabel: __('Target branch'),
    newBranchLabel: __('Branch name'),
    sourceBranchLabel: __('Source branch name'),
    createBranch: __('Create branch'),
    cancelLabel: __('Cancel'),
    createMergeRequest: __('Create merge request'),
    branchNameExists: __('Branch is already taken'),
    branchNameAvailable: __('Branch name is available'),
    branchNameIsRequired: __('Branch name is required'),
    checkingBranchValidity: __('Checking branch validity'),
  },
  createMRModalId: 'create-merge-request-modal',
  mergeRequestHelpPagePath: helpPagePath('user/project/merge_requests/_index.md'),
  inject: ['groupPath'],
  props: {
    showModal: {
      type: Boolean,
      required: false,
      default: false,
    },
    showBranchFlow: {
      type: Boolean,
      required: false,
      default: true,
    },
    workItemIid: {
      type: String,
      required: true,
    },
    workItemType: {
      type: String,
      required: true,
    },
    workItemFullPath: {
      type: String,
      required: true,
    },
    projectId: {
      type: String,
      required: true,
    },
    isConfidentialWorkItem: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isLoading: false,
      canCreateBranch: false,
      branchName: '',
      refName: '',
      invalidBranch: false,
      branchDescription: '',
      checkingBranchValidity: false,
      creatingBranch: false,
      defaultBranch: '',
    };
  },
  apollo: {
    defaultBranch: {
      query: getProjectRootRef,
      variables() {
        return {
          projectFullPath: this.workItemFullPath,
        };
      },
      update(data) {
        return data?.project?.repository?.rootRef || '';
      },
      skip() {
        return !this.workItemFullPath;
      },
      error(e) {
        this.$emit('error', this.$options.i18n.fetchError);
        this.error = e.message || this.$options.i18n.fetchError;
      },
    },
  },
  computed: {
    enabledRefTypes() {
      return this.showBranchFlow ? [REF_TYPE_BRANCHES, REF_TYPE_TAGS] : [REF_TYPE_BRANCHES];
    },
    numericProjectId() {
      return this.projectId.split('/').at(-1);
    },
    refSelectorFieldLabel() {
      return this.showBranchFlow
        ? this.$options.i18n.sourceBranchOrTagLabel
        : this.$options.i18n.targetBranchLabel;
    },
    branchNameFieldLabel() {
      return this.showBranchFlow
        ? this.$options.i18n.newBranchLabel
        : this.$options.i18n.sourceBranchLabel;
    },
    createButtonText() {
      return this.showBranchFlow
        ? this.$options.i18n.createBranch
        : this.$options.i18n.createMergeRequest;
    },
    branchFeedback() {
      const branchErrors = findInvalidBranchNameCharacters(this.branchName);
      if (!this.branchName.length) {
        return this.$options.i18n.branchNameIsRequired;
      }
      if (branchErrors.length) {
        return humanizeBranchValidationErrors(branchErrors);
      }
      return this.$options.i18n.branchNameExists;
    },
    modalTitle() {
      return this.createButtonText;
    },
    isSaveButtonDisabled() {
      return (
        this.invalidBranch ||
        (this.isConfidentialWorkItem && !this.canCreateConfidentialMergeRequest)
      );
    },
    saveButtonAction() {
      return {
        text: this.createButtonText,
        attributes: {
          variant: 'confirm',
          disabled: this.isSaveButtonDisabled,
          loading: this.checkingBranchValidity || this.creatingBranch,
        },
      };
    },
    canCreateConfidentialMergeRequest() {
      return (
        this.isConfidentialWorkItem &&
        Object.keys(confidentialMergeRequestState?.selectedProject).length > 0
      );
    },
    cancelButtonAction() {
      return {
        text: this.$options.i18n.cancelLabel,
      };
    },
    newForkPath() {
      return `/${this.workItemFullPath}/-/forks/new`;
    },
  },
  watch: {
    showModal(newVal, oldVal) {
      if (newVal && newVal !== oldVal) {
        this.init();
      }
    },
  },
  mounted() {
    this.init();
  },
  methods: {
    async init() {
      const createPath = createBranchMRApiPathHelper.canCreateBranch({
        fullPath: this.workItemFullPath,
        workItemIid: this.workItemIid,
      });
      this.isLoading = true;
      const {
        data: { can_create_branch, suggested_branch_name },
      } = await axios.get(createPath);

      this.isLoading = false;
      /** The legacy API is returning values in camelcase format has have to use it here */
      /** Can be changed when we migrate the response to graphql */
      /* eslint-disable camelcase */
      this.canCreateBranch = can_create_branch;
      this.$emit('fetchedPermissions', can_create_branch);

      if (this.canCreateBranch) {
        this.branchName = suggested_branch_name;
        /* eslint-enable camelcase */
        this.refName = this.defaultBranch;
      }
    },
    async createBranch() {
      try {
        const endpoint = createBranchMRApiPathHelper.createBranch(
          this.isConfidentialWorkItem
            ? confidentialMergeRequestState.selectedProject.pathWithNamespace
            : this.workItemFullPath,
        );

        this.creatingBranch = true;

        const { data } = await axios.post(endpoint, {
          branch_name: this.branchName,
          confidential_issue_project_id: this.canCreateConfidentialMergeRequest
            ? this.projectId
            : null,
          format: 'json',
          issue_iid: this.workItemIid,
          ref: this.refName,
        });

        this.$toast.show(__('Branch created.'), {
          autoHideDelay: 10000,
          action: {
            text: __('View branch'),
            onClick: () => visitUrl(data.url),
          },
        });

        this.$emit('hideModal');
      } catch {
        createAlert({
          message: sprintf(
            s__('WorkItem|Failed to create a branch for this %{workItemType}. Please try again.'),
            { workItemType: NAME_TO_TEXT_LOWERCASE_MAP[this.workItemType] },
          ),
        });
      } finally {
        this.creatingBranch = false;
      }
    },
    async createMergeRequest() {
      await this.createBranch();
      const path = createBranchMRApiPathHelper.createMR({
        fullPath: this.isConfidentialWorkItem
          ? confidentialMergeRequestState.selectedProject.pathWithNamespace
          : this.workItemFullPath,
        workItemIid: this.workItemIid,
        sourceBranch: this.branchName,
        targetBranch: this.refName,
      });

      /** open the merge request once we have it created */
      visitUrl(path);
    },
    createEntity() {
      if (this.showBranchFlow) {
        this.createBranch();
      } else {
        this.createMergeRequest();
      }
    },
    fetchRefs(refValue) {
      if (!refValue || !refValue.trim().length) {
        this.invalidBranch = true;
        return;
      }

      this.checkingBranchValidity = true;
      this.branchDescription = __('Checking branch validity…');

      this.refCancelToken = axios.CancelToken.source();

      const refsPath = createBranchMRApiPathHelper.getRefs({
        fullPath: this.isConfidentialWorkItem
          ? confidentialMergeRequestState.selectedProject.pathWithNamespace
          : this.workItemFullPath,
      });

      axios
        .get(`${refsPath}${encodeURIComponent(refValue)}`, {
          cancelToken: this.refCancelToken.token,
        })
        .then(({ data }) => {
          const branches = data?.Branches || [];

          this.invalidBranch =
            branches.includes(refValue) || findInvalidBranchNameCharacters(refValue).length > 0;
        })
        .catch((thrown) => {
          if (axios.isCancel(thrown)) {
            return false;
          }
          createAlert({
            message: __('Failed to get ref.'),
          });
          return false;
        })
        .finally(() => {
          this.checkingBranchValidity = false;
        });
    },
    checkBranchValidity: debounce(function debouncedCheckBranchValidity(refValue) {
      return this.fetchRefs(refValue);
    }, 250),
    hideModal() {
      this.$emit('hideModal');
      this.$nextTick(() => {
        this.invalidBranch = false;
      });
    },
  },
};
</script>

<template>
  <div>
    <gl-modal
      ref="create-modal"
      :visible="showModal || creatingBranch"
      :title="modalTitle"
      :modal-id="$options.createMRModalId"
      :action-primary="saveButtonAction"
      :action-cancel="cancelButtonAction"
      size="sm"
      @primary.prevent="createEntity"
      @hide="hideModal"
    >
      <gl-form class="gl-text-left">
        <project-form-group
          v-if="isConfidentialWorkItem"
          :namespace-path="groupPath"
          :project-path="workItemFullPath"
          :help-page-path="$options.mergeRequestHelpPagePath"
          :new-fork-path="newForkPath"
        />
        <gl-form-group label-for="ref-name-id" :label="refSelectorFieldLabel">
          <ref-selector
            id="ref-name-id"
            v-model="refName"
            :project-id="numericProjectId"
            :enabled-ref-types="enabledRefTypes"
          />
        </gl-form-group>
        <gl-form-group
          required
          label-for="branch-name-id"
          :label="branchNameFieldLabel"
          :description="checkingBranchValidity ? branchDescription : ''"
          :invalid-feedback="checkingBranchValidity || isLoading ? '' : branchFeedback"
          :valid-feedback="
            checkingBranchValidity || isLoading ? '' : $options.i18n.branchNameAvailable
          "
          :state="branchName ? !invalidBranch : false"
        >
          <gl-form-input-group
            id="branch-name-id"
            v-model.trim="branchName"
            data-testid="target-name"
            :state="!invalidBranch"
            :disabled="isLoading || creatingBranch"
            required
            name="branch-name"
            type="text"
            @input="checkBranchValidity($event)"
          >
            <template #append>
              <simple-copy-button :text="branchName" :title="__('Copy to clipboard')" />
            </template>
          </gl-form-input-group>
        </gl-form-group>
      </gl-form>
    </gl-modal>
  </div>
</template>
