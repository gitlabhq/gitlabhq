<script>
import { GlIcon, GlLink } from '@gitlab/ui';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { InternalEvents } from '~/tracking';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import {
  createUserCountsManager,
  userCounts,
  useCachedUserCounts,
} from '~/super_sidebar/user_counts_manager';
import { fetchUserCounts } from '~/super_sidebar/user_counts_fetch';
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
    BaseWidget,
    GlIcon,
    GlLink,
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
    assignedLastUpdatedAt() {
      return this.metadata?.assigned?.nodes?.[0]?.updatedAt ?? null;
    },
    authoredCount() {
      const count = this.metadata?.authored?.count;
      return count != null ? this.formatCount(count) : '-';
    },
    authoredLastUpdatedAt() {
      return this.metadata?.authored?.nodes?.[0]?.updatedAt ?? null;
    },
    assignedCount() {
      const count = userCounts.assigned_issues;
      return count != null ? this.formatCount(count) : '-';
    },
  },
  created() {
    createUserCountsManager();

    if (userCounts.assigned_issues === null) {
      useCachedUserCounts();
      fetchUserCounts();
    }
  },
  methods: {
    formatCount(count) {
      if (Math.abs(count) < 10000) {
        return new Intl.NumberFormat(navigator.language).format(count);
      }
      return new Intl.NumberFormat(navigator.language, {
        notation: 'compact',
        compactDisplay: 'short',
        maximumFractionDigits: 1,
      }).format(count);
    },
    reload() {
      this.hasError = false;
      this.$apollo.queries.metadata.refetch();
    },
    handleVisible() {
      this.reload();
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
  <base-widget :apply-default-styling="false" @visible="handleVisible">
    <div class="gl-grid gl-grid-cols-2 gl-gap-5">
      <gl-link
        class="gl-border gl-flex-1 gl-cursor-pointer gl-rounded-lg gl-border-subtle gl-bg-subtle gl-px-4 gl-py-4 hover:gl-bg-gray-10 dark:hover:gl-bg-alpha-light-8"
        :href="assignedToYouPath"
        :aria-label="s__('HomePageWorkItemsWidget|Work items assigned to you')"
        variant="meta"
        @click="handleAssignedClick"
      >
        <div>
          <div v-if="hasError" class="gl-m-2">
            <div class="gl-flex gl-flex-col gl-items-start gl-gap-4">
              <gl-icon name="error" class="gl-text-red-500" :size="16" />
              <p class="gl-text-size-h5 gl-text-default-400 gl-mb-0">
                {{
                  s__(
                    'HomePageWorkItemsWidget|The number of issues is not available. Please refresh the page to try again, or visit the issue list.',
                  )
                }}
              </p>
            </div>
          </div>
          <div v-else>
            <div class="gl-m-2 gl-flex gl-flex-col-reverse gl-items-start gl-gap-2">
              <h2 class="gl-heading-5 gl-mb-0 gl-font-normal">
                {{ s__('HomePageWorkItemsWidget|Issues assigned to you') }}
              </h2>
              <div class="gl-flex gl-items-center gl-gap-4">
                <div class="gl-heading-1 gl-mb-0" data-testid="assigned-count">
                  {{ assignedCount }}
                </div>
                <gl-icon name="work-item-issue" :size="16" />
              </div>
            </div>
            <span
              v-if="assignedLastUpdatedAt"
              data-testid="assigned-last-updated-at"
              class="gl-text-sm gl-text-gray-400 gl-text-subtle"
            >
              {{ timeFormatted(assignedLastUpdatedAt) }}
            </span>
          </div>
        </div>
      </gl-link>
      <gl-link
        class="gl-border gl-flex-1 gl-cursor-pointer gl-rounded-lg gl-border-subtle gl-bg-subtle gl-p-5 hover:gl-bg-gray-10 dark:hover:gl-bg-alpha-light-8"
        :href="authoredByYouPath"
        :aria-label="s__('HomePageWorkItemsWidget|Work items authored by you')"
        variant="meta"
        @click="handleAuthoredClick"
      >
        <div>
          <div v-if="hasError" class="gl-m-2">
            <div class="gl-flex gl-flex-col gl-items-start gl-gap-4">
              <gl-icon name="error" class="gl-text-red-500" :size="16" />
              <p class="gl-text-size-h3 gl-text-default-400 gl-mb-0">
                {{
                  s__(
                    'HomePageWorkItemsWidget|The number of issues is not available. Please refresh the page to try again, or visit the issue list.',
                  )
                }}
              </p>
            </div>
          </div>
          <div v-else>
            <div class="gl-m-2 gl-flex gl-flex-col-reverse gl-items-start gl-gap-2">
              <h2 class="gl-heading-5 gl-mb-0 gl-font-normal">
                {{ s__('HomePageWorkItemsWidget|Issues authored by you') }}
              </h2>
              <div class="gl-flex gl-items-center gl-gap-4">
                <div class="gl-heading-1 gl-mb-0" data-testid="authored-count">
                  {{ authoredCount }}
                </div>
                <gl-icon name="work-item-issue" :size="16" />
              </div>
            </div>
            <span
              v-if="authoredLastUpdatedAt"
              data-testid="authored-last-updated-at"
              class="gl-text-sm gl-text-gray-400 gl-text-subtle"
            >
              {{ timeFormatted(authoredLastUpdatedAt) }}
            </span>
          </div>
        </div>
      </gl-link>
    </div>
  </base-widget>
</template>
