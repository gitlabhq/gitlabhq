<script>
import { GlIcon, GlLink, GlBadge, GlSprintf } from '@gitlab/ui';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { InternalEvents } from '~/tracking';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import workItemsWidgetMetadataQuery from '../graphql/queries/work_items_widget_metadata.query.graphql';
import {
  EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
  TRACKING_LABEL_ISSUES,
  TRACKING_PROPERTY_ASSIGNED_TO_YOU,
  TRACKING_PROPERTY_AUTHORED_BY_YOU,
} from '../tracking_constants';
import BaseWidget from './base_widget.vue';

export default {
  name: 'WorkItemsWidget',
  components: {
    GlIcon,
    GlLink,
    GlBadge,
    GlSprintf,
    BaseWidget,
  },
  mixins: [timeagoMixin, InternalEvents.mixin()],
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
    handleAssignedClick() {
      this.trackEvent(EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE, {
        label: TRACKING_LABEL_ISSUES,
        property: TRACKING_PROPERTY_ASSIGNED_TO_YOU,
      });
    },
    handleAuthoredClick() {
      this.trackEvent(EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE, {
        label: TRACKING_LABEL_ISSUES,
        property: TRACKING_PROPERTY_AUTHORED_BY_YOU,
      });
    },
  },
};
</script>

<template>
  <base-widget @visible="reload">
    <h2 class="gl-heading-4 gl-mb-4 gl-mt-1 gl-flex gl-items-center gl-gap-2">
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
    <ul v-else class="gl-mb-1 gl-list-none gl-p-0" data-testid="links-list">
      <li>
        <gl-link
          class="gl-flex gl-items-center gl-gap-3 gl-rounded-small gl-px-1 gl-py-1 !gl-no-underline hover:gl-bg-gray-10 dark:hover:gl-bg-alpha-light-8"
          variant="meta"
          :href="assignedToYouPath"
          @click="handleAssignedClick"
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
          @click="handleAuthoredClick"
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
  </base-widget>
</template>
