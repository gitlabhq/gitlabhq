<script>
import { GlIcon, GlLink, GlBadge } from '@gitlab/ui';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import workItemsWidgetMetadataQuery from '../graphql/queries/work_items_widget_metadata.query.graphql';
import VisibilityChangeDetector from './visibility_change_detector.vue';

export default {
  name: 'WorkItemsWidget',
  components: {
    GlIcon,
    GlLink,
    GlBadge,
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
    },
  },
  computed: {
    isLoadingMetadata() {
      return this.$apollo.queries.metadata.loading;
    },
    assignedCount() {
      return this.metadata?.assigned?.count ?? 0;
    },
    assignedLastUpdatedAt() {
      return this.metadata?.assigned?.nodes?.[0]?.updatedAt ?? null;
    },
    authoredCount() {
      return this.metadata?.authored?.count ?? 0;
    },
    authoredLastUpdatedAt() {
      return this.metadata?.authored?.nodes?.[0]?.updatedAt ?? null;
    },
  },
  methods: {
    reload() {
      this.$apollo.queries.metadata.refetch();
    },
  },
};
</script>

<template>
  <visibility-change-detector class="gl-border gl-rounded-lg gl-px-4 gl-py-1" @visible="reload">
    <h4 class="gl-flex gl-items-center gl-gap-2">
      <gl-icon name="issues" :size="16" />{{ __('Issues') }}
    </h4>
    <ul class="gl-list-none gl-p-0">
      <li class="gl-flex gl-items-center gl-gap-3">
        <gl-link
          class="gl-flex gl-items-center gl-gap-3 gl-rounded-small gl-px-1 gl-py-1 !gl-no-underline hover:gl-bg-gray-10 dark:hover:gl-bg-alpha-light-8"
          variant="meta"
          :href="assignedToYouPath"
        >
          {{ s__('HomePageWorkItemsWidget|Assigned to you') }}
        </gl-link>
        <template v-if="!isLoadingMetadata">
          <gl-badge data-testid="assigned-count">{{ assignedCount }}</gl-badge>
          <span
            v-if="assignedLastUpdatedAt"
            data-testid="assigned-last-updated-at"
            class="gl-ml-auto gl-text-sm gl-text-subtle"
            >{{ timeFormatted(assignedLastUpdatedAt) }}</span
          >
        </template>
      </li>
      <li class="gl-flex gl-items-center gl-gap-3">
        <gl-link
          class="gl-flex gl-items-center gl-gap-3 gl-rounded-small gl-px-1 gl-py-1 !gl-no-underline hover:gl-bg-gray-10 dark:hover:gl-bg-alpha-light-8"
          variant="meta"
          :href="authoredByYouPath"
        >
          {{ s__('HomePageWorkItemsWidget|Authored by you') }}
        </gl-link>
        <template v-if="!isLoadingMetadata">
          <gl-badge data-testid="authored-count">{{ authoredCount }}</gl-badge>
          <span
            v-if="authoredLastUpdatedAt"
            data-testid="authored-last-updated-at"
            class="gl-ml-auto gl-text-sm gl-text-subtle"
            >{{ timeFormatted(authoredLastUpdatedAt) }}</span
          >
        </template>
      </li>
    </ul>
  </visibility-change-detector>
</template>
