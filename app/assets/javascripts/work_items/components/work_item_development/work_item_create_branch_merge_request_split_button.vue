<script>
import {
  GlButton,
  GlButtonGroup,
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
} from '@gitlab/ui';
import { __ } from '~/locale';
import WorkItemCreateBranchMergeRequestModal from './work_item_create_branch_merge_request_modal.vue';

export default {
  name: 'WorkItemCreateBranchMergeRequestSplitButton',
  i18n: {
    createMergeRequest: __('Create merge request'),
    createBranch: __('Create branch'),
    branchLabel: __('Branch'),
    mergeRequestLabel: __('Merge request'),
  },
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
    workItemId: {
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
      showBranchFlow: true,
      showMergeRequestFlow: false,
      showCreateBranchAndMrModal: false,
      checkingBranchAvailibility: true,
      showCreateOptions: true,
    };
  },
  computed: {
    mergeRequestGroup() {
      const items = [
        {
          text: this.$options.i18n.createMergeRequest,
          action: this.openModal.bind(this, false, true),
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
          text: this.$options.i18n.createBranch,
          action: this.openModal.bind(this, true, false),
          extraAttrs: {
            'data-testid': 'create-branch-dropdown-button',
          },
        },
      ];

      return { items, name: __('Branch') };
    },
  },
  methods: {
    openModal(createBranch = true, createMergeRequest = false) {
      this.toggleCreateModal(true);
      this.showBranchFlow = createBranch;
      this.showMergeRequestFlow = createMergeRequest;
    },
    toggleCreateModal(showOrhide) {
      this.showCreateBranchAndMrModal = showOrhide;
    },
    updatePermissions(canCreateBranch) {
      this.checkingBranchAvailibility = false;
      this.showCreateOptions = canCreateBranch;
    },
  },
};
</script>

<template>
  <div v-if="showCreateOptions">
    <gl-button-group>
      <gl-button
        :loading="checkingBranchAvailibility"
        icon="merge-request"
        category="primary"
        variant="default"
        size="medium"
        @click="openModal(false, true)"
      >
        {{ $options.i18n.createMergeRequest }}
      </gl-button>
      <gl-disclosure-dropdown
        :toggle-text="__('More options')"
        text-sr-only
        placement="bottom-end"
        data-testid="create-options-dropdown"
      >
        <gl-disclosure-dropdown-group :group="mergeRequestGroup" />

        <gl-disclosure-dropdown-group bordered :group="branchGroup" />
      </gl-disclosure-dropdown>
    </gl-button-group>
    <work-item-create-branch-merge-request-modal
      :show-modal="showCreateBranchAndMrModal"
      :show-branch-flow="showBranchFlow"
      :show-merge-request-flow="showMergeRequestFlow"
      :work-item-iid="workItemIid"
      :work-item-id="workItemId"
      :work-item-type="workItemType"
      :work-item-full-path="workItemFullPath"
      :is-confidential-work-item="isConfidentialWorkItem"
      :project-id="projectId"
      @hideModal="toggleCreateModal(false)"
      @fetchedPermissions="updatePermissions"
    />
  </div>
</template>
