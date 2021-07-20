<script>
import { GlButton } from '@gitlab/ui';
import allReleasesQuery from 'shared_queries/releases/all_releases.query.graphql';
import createFlash from '~/flash';
import { historyPushState } from '~/lib/utils/common_utils';
import { scrollUp } from '~/lib/utils/scroll_utils';
import { setUrlParams, getParameterByName } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import { PAGE_SIZE, DEFAULT_SORT } from '~/releases/constants';
import { convertAllReleasesGraphQLResponse } from '~/releases/util';
import ReleaseBlock from './release_block.vue';
import ReleaseSkeletonLoader from './release_skeleton_loader.vue';
import ReleasesEmptyState from './releases_empty_state.vue';
import ReleasesPaginationApolloClient from './releases_pagination_apollo_client.vue';
import ReleasesSortApolloClient from './releases_sort_apollo_client.vue';

export default {
  name: 'ReleasesIndexApolloClientApp',
  components: {
    GlButton,
    ReleaseBlock,
    ReleaseSkeletonLoader,
    ReleasesEmptyState,
    ReleasesPaginationApolloClient,
    ReleasesSortApolloClient,
  },
  inject: {
    projectPath: {
      default: '',
    },
    newReleasePath: {
      default: '',
    },
  },
  apollo: {
    /**
     * The same query as `fullGraphqlResponse`, except that it limits its
     * results to a single item. This causes this request to complete much more
     * quickly than `fullGraphqlResponse`, which allows the page to show
     * meaningful content to the user much earlier.
     */
    singleGraphqlResponse: {
      query: allReleasesQuery,
      // This trick only works when paginating _forward_.
      // When paginating backwards, limiting the query to a single item loads
      // the _last_ item in the page, which is not useful for our purposes.
      skip() {
        return !this.includeSingleQuery;
      },
      variables() {
        return {
          ...this.queryVariables,
          first: 1,
        };
      },
      update(data) {
        return { data };
      },
      error() {
        this.singleRequestError = true;
      },
    },
    fullGraphqlResponse: {
      query: allReleasesQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return { data };
      },
      error(error) {
        this.fullRequestError = true;

        createFlash({
          message: this.$options.i18n.errorMessage,
          captureError: true,
          error,
        });
      },
    },
  },
  data() {
    return {
      singleRequestError: false,
      fullRequestError: false,
      cursors: {
        before: getParameterByName('before'),
        after: getParameterByName('after'),
      },
      sort: DEFAULT_SORT,
    };
  },
  computed: {
    queryVariables() {
      let paginationParams = { first: PAGE_SIZE };
      if (this.cursors.after) {
        paginationParams = {
          after: this.cursors.after,
          first: PAGE_SIZE,
        };
      } else if (this.cursors.before) {
        paginationParams = {
          before: this.cursors.before,
          last: PAGE_SIZE,
        };
      }

      return {
        fullPath: this.projectPath,
        ...paginationParams,
        sort: this.sort,
      };
    },
    /**
     * @returns {Boolean} Whether or not to request/include
     * the results of the single-item query
     */
    includeSingleQuery() {
      return Boolean(!this.cursors.before || this.cursors.after);
    },
    isSingleRequestLoading() {
      return this.$apollo.queries.singleGraphqlResponse.loading;
    },
    isFullRequestLoading() {
      return this.$apollo.queries.fullGraphqlResponse.loading;
    },
    /**
     * @returns {Boolean} `true` if the `singleGraphqlResponse`
     * query has finished loading without errors
     */
    isSingleRequestLoaded() {
      return Boolean(!this.isSingleRequestLoading && this.singleGraphqlResponse?.data.project);
    },
    /**
     * @returns {Boolean} `true` if the `fullGraphqlResponse`
     * query has finished loading without errors
     */
    isFullRequestLoaded() {
      return Boolean(!this.isFullRequestLoading && this.fullGraphqlResponse?.data.project);
    },
    releases() {
      if (this.isFullRequestLoaded) {
        return convertAllReleasesGraphQLResponse(this.fullGraphqlResponse).data;
      }

      if (this.isSingleRequestLoaded && this.includeSingleQuery) {
        return convertAllReleasesGraphQLResponse(this.singleGraphqlResponse).data;
      }

      return [];
    },
    pageInfo() {
      if (!this.isFullRequestLoaded) {
        return {
          hasPreviousPage: false,
          hasNextPage: false,
        };
      }

      return this.fullGraphqlResponse.data.project.releases.pageInfo;
    },
    shouldRenderEmptyState() {
      return this.isFullRequestLoaded && this.releases.length === 0;
    },
    shouldRenderLoadingIndicator() {
      return (
        (this.isSingleRequestLoading && !this.singleRequestError && !this.isFullRequestLoaded) ||
        (this.isFullRequestLoading && !this.fullRequestError)
      );
    },
    shouldRenderPagination() {
      return this.isFullRequestLoaded && !this.shouldRenderEmptyState;
    },
  },
  created() {
    this.updateQueryParamsFromUrl();

    window.addEventListener('popstate', this.updateQueryParamsFromUrl);
  },
  destroyed() {
    window.removeEventListener('popstate', this.updateQueryParamsFromUrl);
  },
  methods: {
    getReleaseKey(release, index) {
      return [release.tagName, release.name, index].join('|');
    },
    updateQueryParamsFromUrl() {
      this.cursors.before = getParameterByName('before');
      this.cursors.after = getParameterByName('after');
    },
    onPaginationButtonPress() {
      this.updateQueryParamsFromUrl();

      // In some cases, Apollo Client is able to pull its results from the cache instead of making
      // a new network request. In these cases, the page's content gets swapped out immediately without
      // changing the page's scroll, leaving the user looking at the bottom of the new page.
      // To make the experience consistent, regardless of how the data is sourced, we manually
      // scroll to the top of the page every time a pagination button is pressed.
      scrollUp();
    },
    onSortChanged(newSort) {
      if (this.sort === newSort) {
        return;
      }

      // Remove the "before" and "after" query parameters from the URL,
      // effectively placing the user back on page 1 of the results.
      // This prevents the frontend from requesting the results sorted
      // by one field (e.g. `released_at`) while using a pagination cursor
      // intended for a different field (e.g.) `created_at`).
      // For more details, see the MR that introduced this change:
      // https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63434
      historyPushState(
        setUrlParams({
          before: null,
          after: null,
        }),
      );

      this.updateQueryParamsFromUrl();

      this.sort = newSort;
    },
  },
  i18n: {
    newRelease: __('New release'),
    errorMessage: __('An error occurred while fetching the releases. Please try again.'),
  },
};
</script>
<template>
  <div class="flex flex-column mt-2">
    <div class="gl-align-self-end gl-mb-3">
      <releases-sort-apollo-client :value="sort" class="gl-mr-2" @input="onSortChanged" />

      <gl-button
        v-if="newReleasePath"
        :href="newReleasePath"
        :aria-describedby="shouldRenderEmptyState && 'releases-description'"
        category="primary"
        variant="success"
        >{{ $options.i18n.newRelease }}</gl-button
      >
    </div>

    <releases-empty-state v-if="shouldRenderEmptyState" />

    <release-block
      v-for="(release, index) in releases"
      :key="getReleaseKey(release, index)"
      :release="release"
      :class="{ 'linked-card': releases.length > 1 && index !== releases.length - 1 }"
    />

    <release-skeleton-loader v-if="shouldRenderLoadingIndicator" />

    <releases-pagination-apollo-client
      v-if="shouldRenderPagination"
      :page-info="pageInfo"
      @prev="onPaginationButtonPress"
      @next="onPaginationButtonPress"
    />
  </div>
</template>
<style>
.linked-card::after {
  width: 1px;
  content: ' ';
  border: 1px solid #e5e5e5;
  height: 17px;
  top: 100%;
  position: absolute;
  left: 32px;
}
</style>
