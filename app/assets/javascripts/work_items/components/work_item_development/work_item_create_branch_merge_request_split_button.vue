<script>
import {
  GlButton,
  GlButtonGroup,
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
} from '@gitlab/ui';
import { __ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import namespaceMergeRequestsEnabledQuery from '../../graphql/namespace_merge_requests_enabled.query.graphql';
import WorkItemCreateBranchMergeRequestModal from './work_item_create_branch_merge_request_modal.vue';

export default {
  name: 'WorkItemCreateBranchMergeRequestSplitButton',
  components: {
    GlButton,
    GlButtonGroup,
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    WorkItemCreateBranchMergeRequestModal,
  },
  props: {
    workItemFullPath: {
      type: String,
      required: true,
    },
    workItemType: {
      type: String,
      required: true,
    },
    projectId: {
      type: String,
      required: true,
    },
    workItemIid: {
      type: String,
      required: false,
      default: null,
    },
    isConfidentialWorkItem: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      mergeRequestsEnabled: false,
      showBranchFlow: true,
      showModal: false,
      checkingBranchAvailability: true,
      canCreateBranch: true,
    };
  },
  apollo: {
    mergeRequestsEnabled: {
      query: namespaceMergeRequestsEnabledQuery,
      variables() {
        return {
          fullPath: this.workItemFullPath,
        };
      },
      update(data) {
        return data.workspace?.mergeRequestsEnabled ?? false;
      },
      skip() {
        return !this.workItemFullPath;
      },
      error(error) {
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    buttonText() {
      return this.mergeRequestsEnabled ? __('Create merge request') : __('Create branch');
    },
    isLoading() {
      return this.$apollo.queries.mergeRequestsEnabled.loading || this.checkingBranchAvailability;
    },
    mergeRequestGroup() {
      const items = [
        {
          text: __('Create merge request'),
          action: this.openCreateMergeRequestModal,
          extraAttrs: {
            'data-testid': 'create-mr-dropdown-button',
          },
        },
      ];

      return { items, name: __('Merge request') };
    },
    branchGroup() {
      const items = [
        {
          text: __('Create branch'),
          action: this.openCreateBranchModal,
          extraAttrs: {
            'data-testid': 'create-branch-dropdown-button',
          },
        },
      ];

      return { items, name: __('Branch') };
    },
  },
  methods: {
    handleButtonClick() {
      if (this.mergeRequestsEnabled) {
        this.openCreateMergeRequestModal();
      } else {
        this.openCreateBranchModal();
      }
    },
    openCreateBranchModal() {
      this.showBranchFlow = true;
      this.toggleCreateModal(true);
    },
    openCreateMergeRequestModal() {
      this.showBranchFlow = false;
      this.toggleCreateModal(true);
    },
    toggleCreateModal(showModal) {
      this.showModal = showModal;
    },
    updatePermissions(canCreateBranch) {
      this.checkingBranchAvailability = false;
      this.canCreateBranch = canCreateBranch;
    },
  },
};
</script>

<template>
  <div v-if="canCreateBranch">
    <gl-button-group>
      <gl-button
        :loading="isLoading"
        icon="merge-request"
        category="primary"
        variant="default"
        size="medium"
        @click="handleButtonClick"
      >
        {{ buttonText }}
      </gl-button>
      <gl-disclosure-dropdown
        :toggle-text="__('More options')"
        text-sr-only
        placement="bottom-end"
        data-testid="create-options-dropdown"
      >
        <gl-disclosure-dropdown-group v-if="mergeRequestsEnabled" :group="mergeRequestGroup" />
        <gl-disclosure-dropdown-group :bordered="mergeRequestsEnabled" :group="branchGroup" />
      </gl-disclosure-dropdown>
    </gl-button-group>
    <work-item-create-branch-merge-request-modal
      :show-modal="showModal"
      :show-branch-flow="showBranchFlow"
      :work-item-iid="workItemIid"
      :work-item-type="workItemType"
      :work-item-full-path="workItemFullPath"
      :is-confidential-work-item="isConfidentialWorkItem"
      :project-id="projectId"
      @hideModal="toggleCreateModal(false)"
      @fetchedPermissions="updatePermissions"
    />
  </div>
</template>
