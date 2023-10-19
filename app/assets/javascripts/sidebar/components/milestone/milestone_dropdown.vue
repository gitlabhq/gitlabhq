<script>
import { GlDropdownItem } from '@gitlab/ui';
import { TYPENAME_MILESTONE } from '~/graphql_shared/constants';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import {
  TYPE_ISSUE,
  TYPE_MERGE_REQUEST,
  WORKSPACE_GROUP,
  WORKSPACE_PROJECT,
} from '~/issues/constants';
import { __ } from '~/locale';
import { IssuableAttributeType } from '../../constants';
import SidebarDropdown from '../sidebar_dropdown.vue';

const noMilestone = {
  id: 0,
  title: __('No milestone'),
};

const placeholderMilestone = {
  id: -1,
  title: __('Select milestone'),
};

export default {
  issuableAttribute: IssuableAttributeType.Milestone,
  components: {
    GlDropdownItem,
    SidebarDropdown,
  },
  props: {
    attrWorkspacePath: {
      required: true,
      type: String,
    },
    canAdminMilestone: {
      type: Boolean,
      required: false,
      default: false,
    },
    issuableType: {
      type: String,
      required: true,
      validator(value) {
        return [TYPE_ISSUE, TYPE_MERGE_REQUEST].includes(value);
      },
    },
    inputName: {
      type: String,
      required: false,
      default: 'update[milestone_id]',
    },
    milestoneId: {
      type: String,
      required: false,
      default: '',
    },
    milestoneTitle: {
      type: String,
      required: false,
      default: '',
    },
    projectMilestonesPath: {
      type: String,
      required: false,
      default: '',
    },
    workspaceType: {
      type: String,
      required: true,
      validator(value) {
        return [WORKSPACE_GROUP, WORKSPACE_PROJECT].includes(value);
      },
    },
  },
  data() {
    return {
      milestone: this.milestoneId
        ? {
            id: convertToGraphQLId(TYPENAME_MILESTONE, this.milestoneId),
            title: this.milestoneTitle,
          }
        : placeholderMilestone,
    };
  },
  computed: {
    footerItemText() {
      return this.canAdminMilestone ? __('Manage milestones') : __('View milestones');
    },
    value() {
      return this.milestone.id === placeholderMilestone.id
        ? undefined
        : getIdFromGraphQLId(this.milestone.id);
    },
  },
  methods: {
    handleChange(milestone) {
      this.milestone = milestone.id === null ? noMilestone : milestone;
    },
  },
};
</script>

<template>
  <div>
    <input type="hidden" :name="inputName" :value="value" />
    <sidebar-dropdown
      :attr-workspace-path="attrWorkspacePath"
      :current-attribute="milestone"
      :issuable-attribute="$options.issuableAttribute"
      :issuable-type="issuableType"
      :workspace-type="workspaceType"
      data-testid="issuable-milestone-dropdown"
      @change="handleChange"
    >
      <template #footer>
        <gl-dropdown-item v-if="projectMilestonesPath" :href="projectMilestonesPath">
          {{ footerItemText }}
        </gl-dropdown-item>
      </template>
    </sidebar-dropdown>
  </div>
</template>
