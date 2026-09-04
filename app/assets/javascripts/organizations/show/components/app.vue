<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlEmptyState,
  GlSprintf,
} from '@gitlab/ui';
import organizationsEmptyStateSvgPath from '@gitlab/svgs/dist/illustrations/empty-state/empty-organizations-md.svg?url';
import { s__, sprintf } from '~/locale';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';
import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';
import LeaveOrganizationModal from './leave_organization_modal.vue';

export default {
  name: 'OrganizationShowApp',
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlEmptyState,
    GlSprintf,
    HelpPageLink,
    LeaveOrganizationModal,
  },
  mixins: [glSlotsMixin],
  organizationsEmptyStateSvgPath,
  leaveModalId: 'leave-organization-modal',
  props: {
    organization: {
      type: Object,
      required: true,
    },
    canAdminOrganization: {
      type: Boolean,
      required: true,
    },
    canLeaveOrganization: {
      type: Boolean,
      required: false,
      default: false,
    },
    organizationUserGid: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      isLeaveModalVisible: false,
    };
  },
  computed: {
    leaveAction() {
      return {
        text: s__('Organization|Leave organization'),
        variant: 'danger',
        action: this.onLeaveAction,
        extraAttrs: { 'data-testid': 'leave-organization-action' },
      };
    },
    emptyStateTitle() {
      return sprintf(s__('Organization|Welcome to %{organizationName}'), {
        organizationName: this.organization.name,
      });
    },
    emptyStateDescription() {
      if (this.canAdminOrganization) {
        return s__(
          "Organization|%{organizationName} is your organization's home. Manage settings from the sidebar. %{linkStart}Learn more%{linkEnd}.",
        );
      }

      return s__(
        "Organization|%{organizationName} is your organization's home. %{linkStart}Learn more%{linkEnd}.",
      );
    },
    showActionsDropdown() {
      return this.canLeaveOrganization && Boolean(this.organizationUserGid);
    },
  },
  methods: {
    onLeaveAction() {
      this.isLeaveModalVisible = true;
    },
  },
};
</script>

<template>
  <div class="gl-py-6">
    <div v-if="showActionsDropdown" class="gl-flex gl-justify-end">
      <gl-disclosure-dropdown
        icon="ellipsis_v"
        no-caret
        category="tertiary"
        placement="bottom-end"
        :toggle-text="__('Actions')"
        text-sr-only
        data-testid="organization-actions-dropdown"
      >
        <gl-disclosure-dropdown-item :item="leaveAction" />
      </gl-disclosure-dropdown>
    </div>
    <gl-empty-state
      :title="emptyStateTitle"
      :svg-path="$options.organizationsEmptyStateSvgPath"
      :header-level="1"
    >
      <template #description>
        <slot name="description">
          <gl-sprintf :message="emptyStateDescription">
            <template #organizationName
              ><span data-testid="organization-name">{{ organization.name }}</span></template
            >
            <template #link="{ content }">
              <help-page-link href="/user/organization/_index.md">{{ content }}</help-page-link>
            </template>
          </gl-sprintf>
        </slot>
      </template>
      <template v-if="glSlots().actions" #actions>
        <slot name="actions"></slot>
      </template>
    </gl-empty-state>
    <leave-organization-modal
      v-if="showActionsDropdown"
      v-model="isLeaveModalVisible"
      :modal-id="$options.leaveModalId"
      :organization="organization"
      :organization-user-gid="organizationUserGid"
    />
  </div>
</template>
