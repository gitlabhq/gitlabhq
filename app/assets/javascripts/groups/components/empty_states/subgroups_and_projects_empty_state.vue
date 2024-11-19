<script>
import { GlEmptyState } from '@gitlab/ui';
import ActionCard from '~/vue_shared/components/action_card.vue';

import { s__ } from '~/locale';

export default {
  components: { GlEmptyState, ActionCard },
  i18n: {
    title: s__('GroupsEmptyState|There are no subgroups or projects in this group'),
    description: s__(
      'GroupsEmptyState|You do not have necessary permissions to create a subgroup or project in this group. Please contact an owner of this group to create a new subgroup or project.',
    ),
    subgroup: {
      title: s__('GroupsEmptyState|Create subgroup'),
      description: s__('GroupsEmptyState|Use groups to manage multiple projects and members.'),
    },
    project: {
      title: s__('GroupsEmptyState|Create project'),
      description: s__(
        'GroupsEmptyState|Use projects to store and access issues, wiki pages, and other GitLab features.',
      ),
    },
  },
  inject: [
    'newSubgroupPath',
    'newProjectPath',
    'emptyProjectsIllustration',
    'emptySubgroupIllustration',
    'canCreateSubgroups',
    'canCreateProjects',
  ],
  computed: {
    hasActions() {
      return this.canCreateSubgroups || this.canCreateProjects;
    },
    description() {
      return this.hasActions ? null : this.$options.i18n.description;
    },
  },
};
</script>

<template>
  <gl-empty-state
    :title="$options.i18n.title"
    :svg-path="emptySubgroupIllustration"
    :description="description"
  >
    <template v-if="hasActions" #actions>
      <div
        class="gl-mt-5 gl-flex gl-flex-col gl-justify-center gl-gap-4 gl-text-left md:gl-flex-row"
        data-testid="empty-subgroup-and-projects-actions"
      >
        <action-card
          v-if="canCreateSubgroups"
          :title="$options.i18n.subgroup.title"
          :description="$options.i18n.subgroup.description"
          icon="subgroup"
          :href="newSubgroupPath"
          data-testid="create-subgroup"
          class="gl-basis-1/2"
        />
        <action-card
          v-if="canCreateProjects"
          :title="$options.i18n.project.title"
          :description="$options.i18n.project.description"
          icon="project"
          :href="newProjectPath"
          data-testid="create-project"
          class="gl-basis-1/2"
        />
      </div>
    </template>
  </gl-empty-state>
</template>
