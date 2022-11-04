<script>
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { IssuableType, WorkspaceType } from '~/issues/constants';
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
    SidebarDropdown,
  },
  props: {
    attrWorkspacePath: {
      required: true,
      type: String,
    },
    issuableType: {
      type: String,
      required: true,
      validator(value) {
        return [IssuableType.Issue, IssuableType.MergeRequest].includes(value);
      },
    },
    workspaceType: {
      type: String,
      required: true,
      validator(value) {
        return [WorkspaceType.group, WorkspaceType.project].includes(value);
      },
    },
  },
  data() {
    return {
      milestone: placeholderMilestone,
    };
  },
  computed: {
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
    <input type="hidden" name="update[milestone_id]" :value="value" />
    <sidebar-dropdown
      :attr-workspace-path="attrWorkspacePath"
      :current-attribute="milestone"
      :issuable-attribute="$options.issuableAttribute"
      :issuable-type="issuableType"
      :workspace-type="workspaceType"
      @change="handleChange"
    />
  </div>
</template>
