<script>
import { mapActions, mapState } from 'vuex';
import {
  GlEmptyState,
  GlButton,
  GlIcon,
  GlLink,
  GlLoadingIcon,
  GlTable,
  GlFormInput,
  GlDropdown,
  GlDropdownItem,
  GlDropdownDivider,
  GlTooltipDirective,
} from '@gitlab/ui';
import AccessorUtils from '~/lib/utils/accessor';
import Icon from '~/vue_shared/components/icon.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { __ } from '~/locale';
import TrackEventDirective from '~/vue_shared/directives/track_event';
import { trackViewInSentryOptions } from '../utils';

export default {
  fields: [
    { key: 'error', label: __('Open errors'), thClass: 'w-70p' },
    { key: 'events', label: __('Events') },
    { key: 'users', label: __('Users') },
    { key: 'lastSeen', label: __('Last seen'), thClass: 'w-15p' },
  ],
  components: {
    GlEmptyState,
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlTable,
    GlFormInput,
    Icon,
    TimeAgo,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    TrackEvent: TrackEventDirective,
  },
  props: {
    indexPath: {
      type: String,
      required: true,
    },
    enableErrorTrackingLink: {
      type: String,
      required: true,
    },
    errorTrackingEnabled: {
      type: Boolean,
      required: true,
    },
    illustrationPath: {
      type: String,
      required: true,
    },
    userCanEnableErrorTracking: {
      type: Boolean,
      required: true,
    },
  },
  hasLocalStorage: AccessorUtils.isLocalStorageAccessSafe(),
  data() {
    return {
      errorSearchQuery: '',
    };
  },
  computed: {
    ...mapState('list', ['errors', 'externalUrl', 'loading', 'recentSearches']),
  },
  created() {
    if (this.errorTrackingEnabled) {
      this.startPolling(this.indexPath);
    }
  },
  methods: {
    ...mapActions('list', [
      'startPolling',
      'restartPolling',
      'addRecentSearch',
      'clearRecentSearches',
      'loadRecentSearches',
      'setIndexPath',
    ]),
    filterErrors() {
      const searchTerm = this.errorSearchQuery.trim();
      this.addRecentSearch(searchTerm);

      this.startPolling(`${this.indexPath}?search_term=${searchTerm}`);
    },
    setSearchText(text) {
      this.errorSearchQuery = text;
      this.filterErrors();
    },
    trackViewInSentryOptions,
    getDetailsLink(errorId) {
      return `error_tracking/${errorId}/details`;
    },
  },
};
</script>

<template>
  <div>
    <div v-if="errorTrackingEnabled">
      <div class="d-flex flex-row justify-content-around bg-secondary border p-3">
        <div class="filtered-search-box">
          <gl-dropdown
            :text="__('Recent searches')"
            class="filtered-search-history-dropdown-wrapper d-none d-md-block"
            toggle-class="filtered-search-history-dropdown-toggle-button"
            :disabled="loading"
          >
            <div v-if="!$options.hasLocalStorage" class="px-3">
              {{ __('This feature requires local storage to be enabled') }}
            </div>
            <template v-else-if="recentSearches.length > 0">
              <gl-dropdown-item
                v-for="searchQuery in recentSearches"
                :key="searchQuery"
                @click="setSearchText(searchQuery)"
                >{{ searchQuery }}</gl-dropdown-item
              >
              <gl-dropdown-divider />
              <gl-dropdown-item ref="clearRecentSearches" @click="clearRecentSearches">{{
                __('Clear recent searches')
              }}</gl-dropdown-item>
            </template>
            <div v-else class="px-3">{{ __("You don't have any recent searches") }}</div>
          </gl-dropdown>
          <div class="filtered-search-input-container flex-fill">
            <gl-form-input
              v-model="errorSearchQuery"
              class="pl-2 filtered-search"
              :disabled="loading"
              :placeholder="__('Search or filter results…')"
              autofocus
              @keyup.enter.native="filterErrors"
            />
          </div>
          <div class="gl-search-box-by-type-right-icons">
            <gl-button
              v-if="errorSearchQuery.length > 0"
              v-gl-tooltip.hover
              :title="__('Clear')"
              class="clear-search text-secondary"
              name="clear"
              @click="errorSearchQuery = ''"
            >
              <gl-icon name="close" :size="12" />
            </gl-button>
          </div>
        </div>

        <gl-button
          v-track-event="trackViewInSentryOptions(externalUrl)"
          class="ml-3"
          variant="primary"
          :href="externalUrl"
          target="_blank"
        >
          {{ __('View in Sentry') }}
          <icon name="external-link" class="flex-shrink-0" />
        </gl-button>
      </div>

      <div v-if="loading" class="py-3">
        <gl-loading-icon size="md" />
      </div>

      <gl-table
        v-else
        class="mt-3"
        :items="errors"
        :fields="$options.fields"
        :show-empty="true"
        fixed
        stacked="sm"
      >
        <template slot="HEAD_events" slot-scope="data">
          <div class="text-md-right">{{ data.label }}</div>
        </template>
        <template slot="HEAD_users" slot-scope="data">
          <div class="text-md-right">{{ data.label }}</div>
        </template>
        <template slot="error" slot-scope="errors">
          <div class="d-flex flex-column">
            <gl-link class="d-flex text-dark" :href="getDetailsLink(errors.item.id)">
              <strong class="text-truncate">{{ errors.item.title.trim() }}</strong>
            </gl-link>
            <span class="text-secondary text-truncate">
              {{ errors.item.culprit }}
            </span>
          </div>
        </template>

        <template slot="events" slot-scope="errors">
          <div class="text-md-right">{{ errors.item.count }}</div>
        </template>

        <template slot="users" slot-scope="errors">
          <div class="text-md-right">{{ errors.item.userCount }}</div>
        </template>

        <template slot="lastSeen" slot-scope="errors">
          <div class="d-flex align-items-center">
            <time-ago :time="errors.item.lastSeen" class="text-secondary" />
          </div>
        </template>
        <template slot="empty">
          <div ref="empty">
            {{ __('No errors to display.') }}
            <gl-link class="js-try-again" @click="restartPolling">
              {{ __('Check again') }}
            </gl-link>
          </div>
        </template>
      </gl-table>
    </div>
    <div v-else-if="userCanEnableErrorTracking">
      <gl-empty-state
        :title="__('Get started with error tracking')"
        :description="__('Monitor your errors by integrating with Sentry.')"
        :primary-button-text="__('Enable error tracking')"
        :primary-button-link="enableErrorTrackingLink"
        :svg-path="illustrationPath"
      />
    </div>
    <div v-else>
      <gl-empty-state :title="__('Get started with error tracking')" :svg-path="illustrationPath">
        <template #description>
          <div>
            <span>{{ __('Monitor your errors by integrating with Sentry.') }}</span>
            <a href="/help/user/project/operations/error_tracking.html">
              {{ __('More information') }}
            </a>
          </div>
        </template>
      </gl-empty-state>
    </div>
  </div>
</template>
