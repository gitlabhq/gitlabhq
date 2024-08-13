<script>
import { GlLink, GlEmptyState } from '@gitlab/ui';

import { s__ } from '~/locale';

export default {
  components: { GlLink, GlEmptyState },
  i18n: {
    withLinks: {
      subgroup: {
        title: s__('GroupsEmptyState|Create new subgroup'),
        description: s__(
          'GroupsEmptyState|Groups are the best way to manage multiple projects and members.',
        ),
      },
      project: {
        title: s__('GroupsEmptyState|Create new project'),
        description: s__(
          'GroupsEmptyState|Projects are where you can store your code, access issues, wiki, and other features of GitLab.',
        ),
      },
    },
    withoutLinks: {
      title: s__('GroupsEmptyState|No subgroups or projects.'),
      description: s__(
        'GroupsEmptyState|You do not have necessary permissions to create a subgroup or project in this group. Please contact an owner of this group to create a new subgroup or project.',
      ),
    },
  },
  linkClasses: [
    'gl-border',
    '!gl-no-underline',
    'gl-rounded-base',
    'gl-p-7',
    'gl-flex',
    'gl-h-full',
    'gl-items-center',
    'gl-text-purple-600',
    'hover:gl-bg-gray-50',
  ],
  inject: [
    'newSubgroupPath',
    'newProjectPath',
    'newSubgroupIllustration',
    'newProjectIllustration',
    'emptyProjectsIllustration',
    'emptySubgroupIllustration',
    'canCreateSubgroups',
    'canCreateProjects',
  ],
};
</script>

<template>
  <div v-if="canCreateSubgroups || canCreateProjects" class="gl-mt-5">
    <div class="-gl-mx-3 -gl-my-3 gl-flex gl-flex-wrap">
      <div v-if="canCreateSubgroups" class="gl-w-full gl-p-3 sm:gl-w-1/2">
        <gl-link :href="newSubgroupPath" :class="$options.linkClasses">
          <div class="svg-content gl-mr-5 gl-w-15 gl-shrink-0">
            <img :src="newSubgroupIllustration" :alt="$options.i18n.withLinks.subgroup.title" />
          </div>
          <div>
            <h4 class="gl-text-inherit">{{ $options.i18n.withLinks.subgroup.title }}</h4>
            <p class="gl-text-primary">
              {{ $options.i18n.withLinks.subgroup.description }}
            </p>
          </div>
        </gl-link>
      </div>
      <div v-if="canCreateProjects" class="gl-w-full gl-p-3 sm:gl-w-1/2">
        <gl-link :href="newProjectPath" :class="$options.linkClasses">
          <div class="svg-content gl-mr-5 gl-w-13 gl-shrink-0">
            <img :src="newProjectIllustration" :alt="$options.i18n.withLinks.project.title" />
          </div>
          <div>
            <h4 class="gl-text-inherit">{{ $options.i18n.withLinks.project.title }}</h4>
            <p class="gl-text-primary">
              {{ $options.i18n.withLinks.project.description }}
            </p>
          </div>
        </gl-link>
      </div>
    </div>
  </div>
  <gl-empty-state
    v-else
    :title="$options.i18n.withoutLinks.title"
    :svg-path="emptySubgroupIllustration"
    :svg-height="null"
    :description="$options.i18n.withoutLinks.description"
  />
</template>
