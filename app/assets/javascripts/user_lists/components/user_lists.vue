<script>
import { GlBadge, GlButton } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { mapState, mapActions } from 'vuex';
import EmptyState from '~/feature_flags/components/empty_state.vue';
import { buildUrlWithCurrentLocation, historyPushState } from '~/lib/utils/common_utils';
import { objectToQuery, getParameterByName } from '~/lib/utils/url_utility';
import TablePagination from '~/vue_shared/components/pagination/table_pagination.vue';
import UserListsTable from './user_lists_table.vue';

export default {
  components: {
    EmptyState,
    UserListsTable,
    GlBadge,
    GlButton,
    TablePagination,
  },
  inject: {
    newUserListPath: { default: '' },
  },
  data() {
    return {
      page: getParameterByName('page') || '1',
    };
  },
  computed: {
    ...mapState(['userLists', 'alerts', 'count', 'pageInfo', 'isLoading', 'hasError', 'options']),
    canUserRotateToken() {
      return this.rotateInstanceIdPath !== '';
    },
    shouldRenderPagination() {
      return (
        !this.isLoading &&
        !this.hasError &&
        this.userLists.length > 0 &&
        this.pageInfo.total > this.pageInfo.perPage
      );
    },
    shouldShowEmptyState() {
      return !this.isLoading && !this.hasError && this.userLists.length === 0;
    },
    shouldRenderErrorState() {
      return this.hasError && !this.isLoading;
    },
    shouldRenderUserLists() {
      return !this.isLoading && this.userLists.length > 0 && !this.hasError;
    },
    hasNewPath() {
      return !isEmpty(this.newUserListPath);
    },
  },
  created() {
    this.setUserListsOptions({ page: this.page });
    this.fetchUserLists();
  },
  methods: {
    ...mapActions(['setUserListsOptions', 'fetchUserLists', 'clearAlert', 'deleteUserList']),
    onChangePage(page) {
      this.updateUserListsOptions({
        /* URLS parameters are strings, we need to parse to match types */
        page: Number(page).toString(),
      });
    },
    updateUserListsOptions(parameters) {
      const queryString = objectToQuery(parameters);

      historyPushState(buildUrlWithCurrentLocation(`?${queryString}`));
      this.setUserListsOptions(parameters);
      this.fetchUserLists();
    },
  },
};
</script>
<template>
  <div>
    <div class="gl-display-flex gl-flex-direction-column">
      <div class="gl-display-flex gl-flex-direction-column gl-md-display-none!">
        <gl-button v-if="hasNewPath" :href="newUserListPath" variant="confirm">
          {{ s__('UserLists|New user list') }}
        </gl-button>
      </div>
      <div
        class="gl-display-flex gl-align-items-baseline gl-flex-direction-column gl-md-flex-direction-row gl-justify-content-space-between gl-mt-6"
      >
        <div class="gl-display-flex gl-align-items-center">
          <h2 class="gl-font-size-h2 gl-my-0">
            {{ s__('UserLists|User Lists') }}
          </h2>
          <gl-badge v-if="count" class="gl-ml-4">{{ count }}</gl-badge>
        </div>
        <div class="gl-display-flex gl-align-items-center gl-justify-content-end">
          <gl-button v-if="hasNewPath" :href="newUserListPath" variant="confirm">
            {{ s__('UserLists|New user list') }}
          </gl-button>
        </div>
      </div>
      <empty-state
        :alerts="alerts"
        :is-loading="isLoading"
        :loading-label="s__('UserLists|Loading user lists')"
        :error-state="shouldRenderErrorState"
        :error-title="s__('UserLists|There was an error fetching the user lists.')"
        :empty-state="shouldShowEmptyState"
        :empty-title="s__('UserLists|Get started with user lists')"
        :empty-description="
          s__('UserLists|User lists allow you to define a set of users to use with Feature Flags.')
        "
        @dismissAlert="clearAlert"
      >
        <user-lists-table :user-lists="userLists" @delete="deleteUserList" />
      </empty-state>
    </div>
    <table-pagination v-if="shouldRenderPagination" :change="onChangePage" :page-info="pageInfo" />
  </div>
</template>
