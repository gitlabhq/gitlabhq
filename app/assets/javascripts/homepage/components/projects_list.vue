<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { __ } from '~/locale';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import FrecentProjectsQuery from '~/super_sidebar/graphql/queries/current_user_frecent_projects.query.graphql';

const MAX_ITEMS = 10;

export default {
  name: 'ProjectsList',
  components: {
    GlSkeletonLoader,
    ProjectAvatar,
    TooltipOnTruncate,
  },
  data() {
    return {
      projects: [],
      error: null,
    };
  },
  apollo: {
    projects: {
      query: FrecentProjectsQuery,
      update({ frecentProjects = [] }) {
        return frecentProjects.map((project) => ({
          id: project.id,
          title: project.name,
          nameWithNamespace: project.namespace,
          webUrl: `/${project.fullPath}`,
          avatarUrl: project.avatarUrl,
        }));
      },
      error(error) {
        Sentry.captureException(error);
        this.error = error;
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.projects.loading;
    },
    emptyStateMessage() {
      return __('Projects you visit will appear here.');
    },
  },
  methods: {
    reload() {
      this.error = null;
      this.$apollo.queries.projects.refetch();
    },
  },
  MAX_ITEMS,
};
</script>

<template>
  <div data-testid="homepage-quick-access-widget" @visible="reload">
    <p v-if="error" class="gl-mb-0">
      {{
        s__(
          'HomePageProjectsWidget|Your projects are not available. Please refresh the page to try again.',
        )
      }}
    </p>
    <template v-else-if="isLoading">
      <gl-skeleton-loader v-for="i in $options.MAX_ITEMS" :key="i" :height="24">
        <rect x="0" y="0" width="16" height="16" rx="2" ry="2" />
        <rect x="24" y="0" width="200" height="16" rx="2" ry="2" />
      </gl-skeleton-loader>
    </template>

    <p v-else-if="!projects.length" class="gl-my-0 gl-mb-3">
      {{ emptyStateMessage }}
    </p>
    <ul v-else class="gl-m-0 gl-list-none gl-p-0">
      <li v-for="project in projects" :key="project.id">
        <a
          :href="project.webUrl"
          class="-gl-mx-3 gl-flex gl-items-center gl-gap-3 gl-rounded-base gl-p-3 gl-text-default hover:gl-bg-subtle hover:gl-text-default hover:gl-no-underline"
        >
          <project-avatar
            :project-id="project.id"
            :project-name="project.title"
            :project-avatar-url="project.avatarUrl"
            :size="24"
            class="gl-shrink-0"
          />
          <tooltip-on-truncate
            :title="`${project.title} · ${project.nameWithNamespace}`"
            class="gl-min-w-0 gl-overflow-hidden gl-text-ellipsis gl-whitespace-nowrap"
          >
            <span>{{ project.title }}</span>
            <span class="gl-text-subtle">· {{ project.nameWithNamespace }}</span>
          </tooltip-on-truncate>
        </a>
      </li>
    </ul>

    <div v-if="!error && !isLoading && projects.length" class="gl-mt-3">
      <p class="gl-mb-0 gl-text-sm gl-text-subtle">
        {{ __('Displaying frequently visited projects') }}.
      </p>
    </div>
  </div>
</template>
