<script>
import { GlSkeletonLoader, GlCollapsibleListbox, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import axios from '~/lib/utils/axios_utils';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { localTimeAgo } from '~/lib/utils/datetime_utility';
import { s__ } from '~/locale';
import { InternalEvents } from '~/tracking';
import {
  EVENT_USER_CLICKS_LINK_ON_ACTIVITY_FEED,
  TRACKING_SCOPE_YOUR_ACTIVITY,
  TRACKING_SCOPE_STARRED_PROJECTS,
  TRACKING_SCOPE_FOLLOWED_USERS,
} from '../tracking_constants';
import BaseWidget from './base_widget.vue';

const MAX_EVENTS = 5;
const FILTER_OPTIONS = [
  {
    value: null,
    text: s__('HomepageActivityWidget|Your activity'),
    description: s__(
      'HomepageActivityWidget|Your contributions, like commits and work on issues and merge requests.',
    ),
    scope: TRACKING_SCOPE_YOUR_ACTIVITY,
  },
  {
    value: 'starred',
    text: s__('HomepageActivityWidget|Starred projects'),
    description: s__('HomepageActivityWidget|Activity in projects you have starred.'),
    scope: TRACKING_SCOPE_STARRED_PROJECTS,
  },
  {
    value: 'followed',
    text: s__('HomepageActivityWidget|Followed users'),
    description: s__('HomepageActivityWidget|Activity from users you follow.'),
    scope: TRACKING_SCOPE_FOLLOWED_USERS,
  },
];

export default {
  components: {
    GlSkeletonLoader,
    GlCollapsibleListbox,
    BaseWidget,
    GlIcon,
  },
  directives: {
    SafeHtml,
    GlTooltip: GlTooltipDirective,
  },
  mixins: [InternalEvents.mixin()],
  props: {
    activityPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      activityFeedHtml: null,
      isLoading: true,
      hasError: false,
      filter: this.getPersistedFilter(),
    };
  },
  computed: {
    selectedFilterText() {
      const selectedOption = FILTER_OPTIONS.find((option) => option.value === this.filter);
      return selectedOption ? selectedOption.text : s__('HomepageActivityWidget|Your activity');
    },
  },
  watch: {
    filter: {
      handler: 'onFilterChange',
      immediate: false,
    },
  },
  created() {
    this.reload();
  },
  methods: {
    getPersistedFilter() {
      try {
        const savedFilter = sessionStorage.getItem('homepage-activity-filter');
        const validValues = this.$options.FILTER_OPTIONS.map((option) => option.value);
        return validValues.includes(savedFilter) ? savedFilter : null;
      } catch (e) {
        return null;
      }
    },

    handleActivityClick(event) {
      const clickedLink = event.target.closest('a');

      if (clickedLink && clickedLink.href) {
        const currentFilter = this.$options.FILTER_OPTIONS.find(
          (option) => option.value === this.filter,
        );
        this.trackEvent(EVENT_USER_CLICKS_LINK_ON_ACTIVITY_FEED, {
          label: currentFilter.scope,
        });
      }
    },

    onFilterChange(newFilter) {
      try {
        if (newFilter === null) {
          sessionStorage.removeItem('homepage-activity-filter');
        } else {
          sessionStorage.setItem('homepage-activity-filter', newFilter);
        }
      } catch (e) {
        return null;
      }
      this.reload();
      return null;
    },

    async reload() {
      this.isLoading = true;

      try {
        /**
         * As part of this widget's first iteration, we have slightly changed how the `UsersController`
         * controller behaves so that it returns an empty response when the user has no activity and
         * the `is_personal_homepage` param is present. This is a temporary workaround until we can
         * move away from an HTML endpoint and handle empty states more gracefully in the client.
         * We'll need to remove the `is_personal_homepage` logic from `UsersController` once we have
         * a proper GraphQL endpoint here.
         */
        const url = this.filter
          ? `/dashboard/activity?limit=${MAX_EVENTS}&offset=0&filter=${this.filter}`
          : `/users/${encodeURIComponent(gon.current_username)}/activity?limit=${MAX_EVENTS}&is_personal_homepage=1`;
        const { data } = await axios.get(url);
        if (data?.html) {
          const parser = new DOMParser();
          const resp = parser.parseFromString(data.html, 'text/html');
          const timestamps = resp.querySelectorAll('.js-timeago');
          if (timestamps.length > 0) {
            localTimeAgo(timestamps);
          }
          this.activityFeedHtml = resp.body.innerHTML;
        }
      } catch (e) {
        Sentry.captureException(e);
        this.hasError = true;
      } finally {
        this.isLoading = false;
      }
    },
  },
  FILTER_OPTIONS,
};
</script>

<template>
  <base-widget @visible="reload">
    <div class="gl-flex gl-items-center gl-justify-between gl-gap-2">
      <div class="gl-flex gl-items-center gl-gap-2">
        <h2 class="gl-heading-4 gl-m-0">{{ __('Activity') }}</h2>
        <gl-icon
          v-gl-tooltip.hover
          :title="
            s__(
              'HomepageActivityWidget|Filter your activity feed to see different types of events.',
            )
          "
          name="information-o"
          class="gl-text-subtle"
          :size="14"
        />
      </div>

      <gl-collapsible-listbox
        v-model="filter"
        :items="$options.FILTER_OPTIONS"
        :toggle-text="selectedFilterText"
      >
        <template #list-item="{ item }">
          <div class="gl-flex gl-w-full gl-flex-col gl-gap-1">
            <div class="gl-font-weight-semibold gl-text-default">{{ item.text }}</div>
            <div class="gl-line-height-normal gl-text-sm gl-text-subtle">
              {{ item.description }}
            </div>
          </div>
        </template>
      </gl-collapsible-listbox>
    </div>

    <gl-skeleton-loader v-if="isLoading" :width="200">
      <rect width="5" height="3" rx="1" y="2" />
      <rect width="160" height="3" rx="1" x="8" y="2" />
      <rect width="20" height="3" rx="1" x="180" y="2" />

      <rect width="5" height="3" rx="1" y="9" />
      <rect width="160" height="3" rx="1" x="8" y="9" />
      <rect width="20" height="3" rx="1" x="180" y="9" />

      <rect width="5" height="3" rx="1" y="16" />
      <rect width="160" height="3" rx="1" x="8" y="16" />
      <rect width="20" height="3" rx="1" x="180" y="16" />
    </gl-skeleton-loader>
    <p v-else-if="hasError" class="gl-mb-0 gl-pt-3">
      {{
        s__(
          'HomepageActivityWidget|Your activity feed is not available. Please refresh the page to try again.',
        )
      }}
    </p>
    <p v-else-if="!activityFeedHtml" data-testid="empty-state">
      {{
        s__(
          'HomepageActivityWidget|Start creating merge requests, pushing code, commenting in issues, and doing other work to view a feed of your activity here.',
        )
      }}
    </p>
    <ul
      v-else
      v-safe-html="activityFeedHtml"
      data-testid="events-list"
      class="gl-list-none gl-p-0"
      :class="{ 'user-activity-feed': filter === null }"
      @click="handleActivityClick"
    ></ul>
    <a :href="activityPath">{{ __('All activity') }}</a>
  </base-widget>
</template>

<style scoped>
::v-deep .user-profile-activity .system-note-image {
  width: 22px;
  height: 22px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  background-color: var(--gl-background-color-strong);
}

::v-deep .user-profile-activity svg {
  width: 14px;
  height: 14px;
}

::v-deep .user-profile-activity:not(:last-child)::before {
  content: '';
  position: absolute;
  width: 2px;
  left: 10px;
  top: 20px;
  background-color: var(--gl-background-color-strong);
  height: 100%;
}

::v-deep .project-activity-item:not(:last-child)::before {
  content: '';
  position: absolute;
  width: 2px;
  left: 15px;
  top: 20px;
  height: 100%;
  background-color: var(--gl-background-color-strong);
}
</style>
