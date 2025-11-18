<script>
import groupsEmptyStateIllustration from '@gitlab/svgs/dist/illustrations/empty-state/empty-groups-md.svg?url';
import { GlButton } from '@gitlab/ui';
import ResourceListsEmptyState from '~/vue_shared/components/resource_lists/empty_state.vue';
import { s__ } from '~/locale';
import { SEARCH_MINIMUM_LENGTH } from '../../constants';

export default {
  components: { ResourceListsEmptyState, GlButton },
  SEARCH_MINIMUM_LENGTH,
  groupsEmptyStateIllustration,
  i18n: {
    title: s__('GroupsEmptyState|Organize your work with projects and subgroups'),
    noPermissionsTitle: s__('GroupsEmptyState|There are no subgroups or projects in this group'),
    description: s__(
      'GroupsEmptyState|Use projects to store Git repositories and collaborate on issues. Use subgroups as folders to organize related projects and manage team access.',
    ),
    noPermissionsDescription: s__(
      'GroupsEmptyState|You do not have necessary permissions to create a subgroup or project in this group. Please contact an owner of this group to create a new subgroup or project.',
    ),
  },
  inject: ['newSubgroupPath', 'newProjectPath', 'canCreateSubgroups', 'canCreateProjects'],
  props: {
    search: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    hasActions() {
      return this.canCreateSubgroups || this.canCreateProjects;
    },
    description() {
      return this.hasActions
        ? this.$options.i18n.description
        : this.$options.i18n.noPermissionsDescription;
    },
    title() {
      return this.hasActions ? this.$options.i18n.title : this.$options.i18n.noPermissionsTitle;
    },
  },
};
</script>

<template>
  <resource-lists-empty-state
    :title="title"
    :svg-path="$options.groupsEmptyStateIllustration"
    :description="description"
    :search="search"
    :search-minimum-length="$options.SEARCH_MINIMUM_LENGTH"
  >
    <template v-if="hasActions" #actions>
      <div
        class="gl-flex gl-flex-col gl-justify-center gl-gap-3 gl-text-left @md/panel:gl-flex-row"
        data-testid="empty-subgroup-and-projects-actions"
      >
        <gl-button
          v-if="canCreateProjects"
          :href="newProjectPath"
          data-testid="create-project"
          variant="confirm"
          category="primary"
        >
          {{ __('Create project') }}
        </gl-button>
        <gl-button
          v-if="canCreateSubgroups"
          :href="newSubgroupPath"
          data-testid="create-subgroup"
          :variant="canCreateProjects ? 'default' : 'confirm'"
          :category="canCreateProjects ? 'secondary' : 'primary'"
        >
          {{ __('Create subgroup') }}
        </gl-button>
      </div>
    </template>
  </resource-lists-empty-state>
</template>
