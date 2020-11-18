<script>
import { mapState, mapActions } from 'vuex';
import { isEmpty } from 'lodash';
import { GlAlert, GlButton, GlModalDirective, GlSprintf, GlTabs } from '@gitlab/ui';

import { FEATURE_FLAG_SCOPE, USER_LIST_SCOPE } from '../constants';
import FeatureFlagsTab from './feature_flags_tab.vue';
import FeatureFlagsTable from './feature_flags_table.vue';
import UserListsTable from './user_lists_table.vue';
import { s__ } from '~/locale';
import TablePagination from '~/vue_shared/components/pagination/table_pagination.vue';
import {
  buildUrlWithCurrentLocation,
  getParameterByName,
  historyPushState,
} from '~/lib/utils/common_utils';

import ConfigureFeatureFlagsModal from './configure_feature_flags_modal.vue';

const SCOPES = { FEATURE_FLAG_SCOPE, USER_LIST_SCOPE };

export default {
  components: {
    ConfigureFeatureFlagsModal,
    FeatureFlagsTab,
    FeatureFlagsTable,
    GlAlert,
    GlButton,
    GlSprintf,
    GlTabs,
    TablePagination,
    UserListsTable,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  inject: {
    newUserListPath: { default: '' },
    newFeatureFlagPath: { default: '' },
    canUserConfigure: { required: true },
    featureFlagsLimitExceeded: { required: true },
  },
  data() {
    const scope = getParameterByName('scope') || SCOPES.FEATURE_FLAG_SCOPE;
    return {
      scope,
      page: getParameterByName('page') || '1',
      isUserListAlertDismissed: false,
      shouldShowFeatureFlagsLimitWarning: this.featureFlagsLimitExceeded,
      selectedTab: Object.values(SCOPES).indexOf(scope),
    };
  },
  computed: {
    ...mapState([
      FEATURE_FLAG_SCOPE,
      USER_LIST_SCOPE,
      'alerts',
      'count',
      'pageInfo',
      'isLoading',
      'hasError',
      'options',
      'instanceId',
      'isRotating',
      'hasRotateError',
    ]),
    topAreaBaseClasses() {
      return ['gl-display-flex', 'gl-flex-direction-column'];
    },
    canUserRotateToken() {
      return this.rotateInstanceIdPath !== '';
    },
    currentlyDisplayedData() {
      return this.dataForScope(this.scope);
    },
    shouldRenderPagination() {
      return (
        !this.isLoading &&
        !this.hasError &&
        this.currentlyDisplayedData.length > 0 &&
        this.pageInfo[this.scope].total > this.pageInfo[this.scope].perPage
      );
    },
    shouldShowEmptyState() {
      return !this.isLoading && !this.hasError && this.currentlyDisplayedData.length === 0;
    },
    shouldRenderErrorState() {
      return this.hasError && !this.isLoading;
    },
    shouldRenderFeatureFlags() {
      return this.shouldRenderTable(SCOPES.FEATURE_FLAG_SCOPE);
    },
    shouldRenderUserLists() {
      return this.shouldRenderTable(SCOPES.USER_LIST_SCOPE);
    },
    hasNewPath() {
      return !isEmpty(this.newFeatureFlagPath);
    },
    emptyStateTitle() {
      return s__('FeatureFlags|Get started with feature flags');
    },
  },
  created() {
    this.setFeatureFlagsOptions({ scope: this.scope, page: this.page });
    this.fetchFeatureFlags();
    this.fetchUserLists();
  },
  methods: {
    ...mapActions([
      'setFeatureFlagsOptions',
      'fetchFeatureFlags',
      'fetchUserLists',
      'rotateInstanceId',
      'toggleFeatureFlag',
      'deleteUserList',
      'clearAlert',
    ]),
    onChangeTab(scope) {
      this.scope = scope;
      this.updateFeatureFlagOptions({
        scope,
        page: '1',
      });
    },
    onFeatureFlagsTab() {
      this.onChangeTab(SCOPES.FEATURE_FLAG_SCOPE);
    },
    onUserListsTab() {
      this.onChangeTab(SCOPES.USER_LIST_SCOPE);
    },
    onChangePage(page) {
      this.updateFeatureFlagOptions({
        scope: this.scope,
        /* URLS parameters are strings, we need to parse to match types */
        page: Number(page).toString(),
      });
    },
    updateFeatureFlagOptions(parameters) {
      const queryString = Object.keys(parameters)
        .map(parameter => {
          const value = parameters[parameter];
          return `${parameter}=${encodeURIComponent(value)}`;
        })
        .join('&');

      historyPushState(buildUrlWithCurrentLocation(`?${queryString}`));
      this.setFeatureFlagsOptions(parameters);
      if (this.scope === SCOPES.FEATURE_FLAG_SCOPE) {
        this.fetchFeatureFlags();
      } else {
        this.fetchUserLists();
      }
    },
    shouldRenderTable(scope) {
      return (
        !this.isLoading &&
        this.dataForScope(scope).length > 0 &&
        !this.hasError &&
        this.scope === scope
      );
    },
    dataForScope(scope) {
      return this[scope];
    },
    onDismissFeatureFlagsLimitWarning() {
      this.shouldShowFeatureFlagsLimitWarning = false;
    },
    onNewFeatureFlagCLick() {
      if (this.featureFlagsLimitExceeded) {
        this.shouldShowFeatureFlagsLimitWarning = true;
      }
    },
  },
};
</script>
<template>
  <div>
    <gl-alert
      v-if="shouldShowFeatureFlagsLimitWarning"
      variant="warning"
      @dismiss="onDismissFeatureFlagsLimitWarning"
    >
      <gl-sprintf
        :message="
          s__(
            'FeatureFlags|Feature flags limit reached (%{featureFlagsLimit}). Delete one or more feature flags before adding new ones.',
          )
        "
      >
        <template #featureFlagsLimit>
          <span>{{ featureFlagsLimit }}</span>
        </template>
      </gl-sprintf>
    </gl-alert>
    <configure-feature-flags-modal
      v-if="canUserConfigure"
      :instance-id="instanceId"
      :is-rotating="isRotating"
      :has-rotate-error="hasRotateError"
      :can-user-rotate-token="canUserRotateToken"
      modal-id="configure-feature-flags"
      @token="rotateInstanceId()"
    />
    <div :class="topAreaBaseClasses">
      <div class="gl-display-flex gl-flex-direction-column gl-display-md-none!">
        <gl-button
          v-if="canUserConfigure"
          v-gl-modal="'configure-feature-flags'"
          variant="info"
          category="secondary"
          data-qa-selector="configure_feature_flags_button"
          data-testid="ff-configure-button"
          class="gl-mb-3"
        >
          {{ s__('FeatureFlags|Configure') }}
        </gl-button>

        <gl-button
          v-if="newUserListPath"
          :href="newUserListPath"
          variant="success"
          category="secondary"
          class="gl-mb-3"
          data-testid="ff-new-list-button"
        >
          {{ s__('FeatureFlags|New user list') }}
        </gl-button>

        <gl-button
          v-if="hasNewPath"
          :href="featureFlagsLimitExceeded ? '' : newFeatureFlagPath"
          variant="success"
          data-testid="ff-new-button"
          @click="onNewFeatureFlagCLick"
        >
          {{ s__('FeatureFlags|New feature flag') }}
        </gl-button>
      </div>
      <gl-tabs v-model="selectedTab" class="gl-align-items-center gl-w-full">
        <feature-flags-tab
          :title="s__('FeatureFlags|Feature Flags')"
          :count="count.featureFlags"
          :alerts="alerts"
          :is-loading="isLoading"
          :loading-label="s__('FeatureFlags|Loading feature flags')"
          :error-state="shouldRenderErrorState"
          :error-title="s__(`FeatureFlags|There was an error fetching the feature flags.`)"
          :empty-state="shouldShowEmptyState"
          :empty-title="emptyStateTitle"
          data-testid="feature-flags-tab"
          @dismissAlert="clearAlert"
          @changeTab="onFeatureFlagsTab"
        >
          <feature-flags-table
            v-if="shouldRenderFeatureFlags"
            :feature-flags="featureFlags"
            @toggle-flag="toggleFeatureFlag"
          />
        </feature-flags-tab>
        <feature-flags-tab
          :title="s__('FeatureFlags|User Lists')"
          :count="count.userLists"
          :alerts="alerts"
          :is-loading="isLoading"
          :loading-label="s__('FeatureFlags|Loading user lists')"
          :error-state="shouldRenderErrorState"
          :error-title="s__(`FeatureFlags|There was an error fetching the user lists.`)"
          :empty-state="shouldShowEmptyState"
          :empty-title="emptyStateTitle"
          data-testid="user-lists-tab"
          @dismissAlert="clearAlert"
          @changeTab="onUserListsTab"
        >
          <user-lists-table
            v-if="shouldRenderUserLists"
            :user-lists="userLists"
            @delete="deleteUserList"
          />
        </feature-flags-tab>
        <template #tabs-end>
          <li
            class="gl-display-none gl-display-md-flex gl-align-items-center gl-flex-fill-1 gl-justify-content-end"
          >
            <gl-button
              v-if="canUserConfigure"
              v-gl-modal="'configure-feature-flags'"
              variant="info"
              category="secondary"
              data-qa-selector="configure_feature_flags_button"
              data-testid="ff-configure-button"
              class="gl-mb-0 gl-mr-4"
            >
              {{ s__('FeatureFlags|Configure') }}
            </gl-button>

            <gl-button
              v-if="newUserListPath"
              :href="newUserListPath"
              variant="success"
              category="secondary"
              class="gl-mb-0 gl-mr-4"
              data-testid="ff-new-list-button"
            >
              {{ s__('FeatureFlags|New user list') }}
            </gl-button>

            <gl-button
              v-if="hasNewPath"
              :href="featureFlagsLimitExceeded ? '' : newFeatureFlagPath"
              variant="success"
              data-testid="ff-new-button"
              @click="onNewFeatureFlagCLick"
            >
              {{ s__('FeatureFlags|New feature flag') }}
            </gl-button>
          </li>
        </template>
      </gl-tabs>
    </div>
    <table-pagination
      v-if="shouldRenderPagination"
      :change="onChangePage"
      :page-info="pageInfo[scope]"
    />
  </div>
</template>
