<script>
import { GlForm, GlFormInput, GlFormGroup, GlModal } from '@gitlab/ui';
import { debounce } from 'lodash';
import axios from '~/lib/utils/axios_utils';
import { createAlert } from '~/alert';
import {
  sprintfWorkItem,
  WORK_ITEM_CREATE_ENTITY_MODAL_TARGET_SOURCE,
  WORK_ITEM_CREATE_ENTITY_MODAL_TARGET_BRANCH,
} from '~/work_items/constants';
import { visitUrl } from '~/lib/utils/url_utility';
import { createBranchMRApiPathHelper } from '~/work_items/utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import {
  findInvalidBranchNameCharacters,
  humanizeBranchValidationErrors,
} from '~/lib/utils/text_utility';
import getProjectRootRef from '~/work_items/graphql/get_project_root_ref.query.graphql';
import { s__, __ } from '~/locale';
import confidentialMergeRequestState from '~/confidential_merge_request/state';
import ProjectFormGroup from '~/confidential_merge_request/components/project_form_group.vue';

export default {
  components: {
    GlForm,
    GlFormInput,
    GlFormGroup,
    GlModal,
    ProjectFormGroup,
  },
  i18n: {
    sourceLabel: __('Source (branch or tag)'),
    branchLabel: __('Branch name'),
    createBranch: __('Create branch'),
    cancelLabel: __('Cancel'),
    createMergeRequest: __('Create merge request'),
    branchNameExists: __('Branch is already taken'),
    sourceNotAvailable: __('Source is not available'),
    branchNameAvailable: __('Branch name is available'),
    sourceIsAvailable: __('Source is available'),
    branchNameIsRequired: __('Branch name is required'),
    sourceNameIsRequired: __('Source name is required'),
    checkingSourceValidity: __('Checking source validity'),
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
    showMergeRequestFlow: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemIid: {
      type: String,
      required: true,
    },
    workItemId: {
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
      sourceName: '',
      invalidSource: false,
      invalidBranch: false,
      invalidForm: false,
      sourceDescription: '',
      branchDescription: '',
      checkingSourceValidity: false,
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
    createButtonText() {
      return this.showBranchFlow
        ? this.$options.i18n.createBranch
        : this.$options.i18n.createMergeRequest;
    },
    sourceFeedback() {
      return this.sourceName?.length
        ? this.$options.i18n.sourceNotAvailable
        : this.$options.i18n.sourceNameIsRequired;
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
        this.invalidForm || (this.isConfidentialWorkItem && !this.canCreateConfidentialMergeRequest)
      );
    },
    saveButtonAction() {
      return {
        text: this.createButtonText,
        attributes: {
          variant: 'confirm',
          disabled: this.isSaveButtonDisabled,
          loading:
            this.checkingSourceValidity || this.checkingBranchValidity || this.creatingBranch,
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
        this.sourceName = this.defaultBranch;
      }
    },
    async createBranch() {
      try {
        const endpoint = createBranchMRApiPathHelper.createBranch({
          fullPath: this.isConfidentialWorkItem
            ? confidentialMergeRequestState.selectedProject.pathWithNamespace
            : this.workItemFullPath,
          workItemIid: this.workItemIid,
          sourceBranch: this.defaultBranch,
          targetBranch: this.branchName,
        });

        this.creatingBranch = true;
        const { data } = await axios.post(endpoint, {
          confidential_issue_project_id: this.canCreateConfidentialMergeRequest
            ? this.projectId
            : null,
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
          message: sprintfWorkItem(
            s__('WorkItem|Failed to create a branch for this %{workItemType}. Please try again.'),
            this.workItemType?.toLowerCase(),
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
        targetBranch: this.defaultBranch,
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
    fetchRefs(refValue, target) {
      if (!refValue || !refValue.trim().length) {
        this.invalidSource = target === WORK_ITEM_CREATE_ENTITY_MODAL_TARGET_SOURCE;
        this.invalidBranch = target === WORK_ITEM_CREATE_ENTITY_MODAL_TARGET_BRANCH;
        this.invalidForm = true;
        return;
      }

      if (target === WORK_ITEM_CREATE_ENTITY_MODAL_TARGET_SOURCE) {
        this.checkingSourceValidity = true;
        this.sourceDescription = __('Checking source validity...');
      } else {
        this.checkingBranchValidity = true;
        this.branchDescription = __('Checking branch validity...');
      }

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
          const branches = data.Branches;
          const tags = data.Tags;

          if (target === WORK_ITEM_CREATE_ENTITY_MODAL_TARGET_SOURCE) {
            this.invalidSource = !(
              branches.indexOf(refValue) !== -1 || tags.indexOf(refValue) !== -1
            );
          } else {
            this.invalidBranch = Boolean(
              branches.indexOf(refValue) !== -1 || findInvalidBranchNameCharacters(refValue).length,
            );
          }

          this.invalidForm = this.invalidSource || this.invalidBranch;
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
          this.checkingSourceValidity = false;
          this.checkingBranchValidity = false;
        });
    },
    checkValidity: debounce(function debouncedCheckValidity(refValue, target) {
      return this.fetchRefs(refValue, target);
    }, 250),
    hideModal() {
      this.$emit('hideModal');
      this.$nextTick(() => {
        this.invalidBranch = false;
        this.invalidSource = false;
        this.invalidForm = false;
      });
    },
  },
  WORK_ITEM_CREATE_ENTITY_MODAL_TARGET_SOURCE,
  WORK_ITEM_CREATE_ENTITY_MODAL_TARGET_BRANCH,
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
        <gl-form-group
          required
          label-for="source-name-id"
          :label="$options.i18n.sourceLabel"
          :description="checkingSourceValidity ? sourceDescription : ''"
          :invalid-feedback="checkingSourceValidity || isLoading ? '' : sourceFeedback"
          :valid-feedback="
            checkingSourceValidity || isLoading ? '' : $options.i18n.sourceIsAvailable
          "
          :state="sourceName ? !invalidSource : false"
        >
          <gl-form-input
            id="source-name-id"
            v-model.trim="sourceName"
            :state="!invalidSource"
            required
            name="source-name"
            type="text"
            :disabled="isLoading || creatingBranch"
            @input="checkValidity($event, $options.WORK_ITEM_CREATE_ENTITY_MODAL_TARGET_SOURCE)"
          />
        </gl-form-group>
        <gl-form-group
          required
          label-for="branch-name-id"
          :label="$options.i18n.branchLabel"
          :description="checkingBranchValidity ? branchDescription : ''"
          :invalid-feedback="checkingBranchValidity || isLoading ? '' : branchFeedback"
          :valid-feedback="
            checkingBranchValidity || isLoading ? '' : $options.i18n.branchNameAvailable
          "
          :state="branchName ? !invalidBranch : false"
        >
          <gl-form-input
            id="branch-name-id"
            v-model.trim="branchName"
            :state="!invalidBranch"
            :disabled="isLoading || creatingBranch"
            required
            name="branch-name"
            type="text"
            @input="checkValidity($event, $options.WORK_ITEM_CREATE_ENTITY_MODAL_TARGET_BRANCH)"
          />
        </gl-form-group>
      </gl-form>
    </gl-modal>
  </div>
</template>
