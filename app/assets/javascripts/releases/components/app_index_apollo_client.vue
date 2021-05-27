<script>
import { GlButton } from '@gitlab/ui';
import createFlash from '~/flash';
import { getParameterByName } from '~/lib/utils/common_utils';
import { scrollUp } from '~/lib/utils/scroll_utils';
import { __ } from '~/locale';
import { PAGE_SIZE } from '~/releases/constants';
import allReleasesQuery from '~/releases/graphql/queries/all_releases.query.graphql';
import { convertAllReleasesGraphQLResponse } from '~/releases/util';
import ReleaseBlock from './release_block.vue';
import ReleaseSkeletonLoader from './release_skeleton_loader.vue';
import ReleasesEmptyState from './releases_empty_state.vue';
import ReleasesPaginationApolloClient from './releases_pagination_apollo_client.vue';

export default {
  name: 'ReleasesIndexApolloClientApp',
  components: {
    GlButton,
    ReleaseBlock,
    ReleaseSkeletonLoader,
    ReleasesEmptyState,
    ReleasesPaginationApolloClient,
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
    graphqlResponse: {
      query: allReleasesQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return { data };
      },
      error(error) {
        this.hasError = true;

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
      hasError: false,
      cursors: {
        before: getParameterByName('before'),
        after: getParameterByName('after'),
      },
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
      };
    },
    isLoading() {
      return this.$apollo.queries.graphqlResponse.loading;
    },
    releases() {
      if (!this.graphqlResponse || this.hasError) {
        return [];
      }

      return convertAllReleasesGraphQLResponse(this.graphqlResponse).data;
    },
    pageInfo() {
      if (!this.graphqlResponse || this.hasError) {
        return {
          hasPreviousPage: false,
          hasNextPage: false,
        };
      }

      return this.graphqlResponse.data.project.releases.pageInfo;
    },
    shouldRenderEmptyState() {
      return !this.releases.length && !this.hasError && !this.isLoading;
    },
    shouldRenderSuccessState() {
      return this.releases.length && !this.isLoading && !this.hasError;
    },
    shouldRenderLoadingIndicator() {
      return this.isLoading && !this.hasError;
    },
    shouldRenderPagination() {
      return (
        !this.isLoading &&
        !this.hasError &&
        (this.pageInfo.hasPreviousPage || this.pageInfo.hasNextPage)
      );
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
      <gl-button
        v-if="newReleasePath"
        :href="newReleasePath"
        :aria-describedby="shouldRenderEmptyState && 'releases-description'"
        category="primary"
        variant="success"
        >{{ $options.i18n.newRelease }}</gl-button
      >
    </div>

    <release-skeleton-loader v-if="shouldRenderLoadingIndicator" />

    <releases-empty-state v-else-if="shouldRenderEmptyState" />

    <div v-else-if="shouldRenderSuccessState">
      <release-block
        v-for="(release, index) in releases"
        :key="index"
        :release="release"
        :class="{ 'linked-card': releases.length > 1 && index !== releases.length - 1 }"
      />
    </div>

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
