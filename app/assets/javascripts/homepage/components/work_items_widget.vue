<script>
import { GlIcon, GlLink, GlBadge, GlSprintf } from '@gitlab/ui';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import workItemsWidgetMetadataQuery from '../graphql/queries/work_items_widget_metadata.query.graphql';
import VisibilityChangeDetector from './visibility_change_detector.vue';

export default {
  name: 'WorkItemsWidget',
  components: {
    GlIcon,
    GlLink,
    GlBadge,
    GlSprintf,
    VisibilityChangeDetector,
  },
  mixins: [timeagoMixin],
  props: {
    assignedToYouPath: {
      type: String,
      required: true,
    },
    authoredByYouPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      metadata: {},
      hasError: false,
    };
  },
  apollo: {
    metadata: {
      query: workItemsWidgetMetadataQuery,
      variables() {
        return { username: gon.current_username };
      },
      update({ currentUser }) {
        return currentUser;
      },
      error(error) {
        this.hasError = true;
        Sentry.captureException(error);
      },
    },
  },
  computed: {
    assignedCount() {
      return this.metadata?.assigned?.count ?? '-';
    },
    assignedLastUpdatedAt() {
      return this.metadata?.assigned?.nodes?.[0]?.updatedAt ?? null;
    },
    authoredCount() {
      return this.metadata?.authored?.count ?? '-';
    },
    authoredLastUpdatedAt() {
      return this.metadata?.authored?.nodes?.[0]?.updatedAt ?? null;
    },
  },
  methods: {
    reload() {
      this.hasError = false;
      this.$apollo.queries.metadata.refetch();
    },
  },
};
</script>

<template>
  <visibility-change-detector class="gl-border gl-rounded-lg gl-px-4 gl-py-1" @visible="reload">
    <h2 class="gl-heading-4 gl-my-4 gl-flex gl-items-center gl-gap-2">
      <gl-icon name="issues" :size="16" />{{ __('Issues') }}
    </h2>
    <p v-if="hasError" data-testid="error-message">
      <gl-sprintf
        :message="
          s__(
            'HomePageWorkItemsWidget|The number of issues is not available. Please refresh the page to try again, or visit the %{linkStart}issue list%{linkEnd}.',
          )
        "
      >
        <template #link="{ content }">
          <gl-link :href="assignedToYouPath">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
    <ul v-else class="gl-list-none gl-p-0" data-testid="links-list">
      <li>
        <gl-link
          class="gl-flex gl-items-center gl-gap-3 gl-rounded-small gl-px-1 gl-py-1 !gl-no-underline hover:gl-bg-gray-10 dark:hover:gl-bg-alpha-light-8"
          variant="meta"
          :href="assignedToYouPath"
        >
          {{ s__('HomePageWorkItemsWidget|Assigned to you') }}
          <gl-badge data-testid="assigned-count">{{ assignedCount }}</gl-badge>
          <span
            v-if="assignedLastUpdatedAt"
            data-testid="assigned-last-updated-at"
            class="gl-ml-auto gl-text-sm gl-text-subtle"
            >{{ timeFormatted(assignedLastUpdatedAt) }}</span
          >
        </gl-link>
      </li>
      <li>
        <gl-link
          class="gl-flex gl-items-center gl-gap-3 gl-rounded-small gl-px-1 gl-py-1 !gl-no-underline hover:gl-bg-gray-10 dark:hover:gl-bg-alpha-light-8"
          variant="meta"
          :href="authoredByYouPath"
        >
          {{ s__('HomePageWorkItemsWidget|Authored by you') }}
          <gl-badge data-testid="authored-count">{{ authoredCount }}</gl-badge>
          <span
            v-if="authoredLastUpdatedAt"
            data-testid="authored-last-updated-at"
            class="gl-ml-auto gl-text-sm gl-text-subtle"
            >{{ timeFormatted(authoredLastUpdatedAt) }}</span
          >
        </gl-link>
      </li>
    </ul>
  </visibility-change-detector>
</template>
