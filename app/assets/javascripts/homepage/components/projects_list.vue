<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { __ } from '~/locale';
import { PROJECT_SOURCE_FRECENT, PROJECT_SOURCE_STARRED } from '~/homepage/constants';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate/tooltip_on_truncate.vue';
import userProjectsQuery from '~/homepage/graphql/queries/user_projects.query.graphql';

const MAX_ITEMS = 10;

export default {
  name: 'ProjectsList',
  components: {
    GlSkeletonLoader,
    ProjectAvatar,
    TooltipOnTruncate,
  },
  props: {
    selectedSources: {
      type: Array,
      required: false,
      default: () => [PROJECT_SOURCE_FRECENT],
    },
  },
  data() {
    return {
      projects: [],
      error: null,
    };
  },
  apollo: {
    projects: {
      query: userProjectsQuery,
      variables() {
        return {
          limit: MAX_ITEMS,
          includeFrecent: this.selectedSources.includes(PROJECT_SOURCE_FRECENT),
          includeStarred: this.selectedSources.includes(PROJECT_SOURCE_STARRED),
        };
      },
      update(data) {
        const projects = [];
        const seenIds = new Set();

        const addProjects = (projectList) => {
          for (const project of projectList) {
            if (projects.length >= MAX_ITEMS) break;
            if (!seenIds.has(project.id)) {
              projects.push({
                id: project.id,
                title: project.name,
                nameWithNamespace: project.namespace,
                webPath: project.webPath,
                avatarUrl: project.avatarUrl,
              });
              seenIds.add(project.id);
            }
          }
        };

        if (data.frecentProjects) {
          addProjects(data.frecentProjects);
        }

        if (data.currentUser?.starredProjects?.nodes) {
          addProjects(data.currentUser.starredProjects.nodes);
        }

        return projects;
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
    footerMessage() {
      if (this.selectedSources.length === 2) {
        return __('Displaying frequently visited and starred projects.');
      }
      return this.selectedSources.includes(PROJECT_SOURCE_FRECENT)
        ? __('Displaying frequently visited projects.')
        : __('Displaying starred projects.');
    },
  },
  methods: {
    reload() {
      this.error = null;
      this.$apollo.queries.projects.refetch();
    },
  },
  MAX_ITEMS,
  PROJECT_SOURCE_FRECENT,
  PROJECT_SOURCE_STARRED,
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
      <div class="gl-flex gl-flex-col gl-gap-y-4 gl-pt-3">
        <gl-skeleton-loader
          v-for="i in $options.MAX_ITEMS"
          :key="i"
          :lines="1"
          :equal-width-lines="true"
        />
      </div>
    </template>

    <p v-else-if="!projects.length" class="gl-my-0 gl-my-3 gl-text-subtle">
      {{ __('No projects match your selected display options.') }}
    </p>
    <ul v-else class="gl-m-0 gl-list-none gl-p-0">
      <li v-for="project in projects" :key="project.id">
        <a
          :href="project.webPath"
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
        {{ footerMessage }}
      </p>
    </div>
  </div>
</template>
