<script>
import { GlAlert, GlButton, GlLink, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { historyPushState } from '~/lib/utils/common_utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import { scrollUp } from '~/lib/utils/scroll_utils';
import { setUrlParams, getParameterByName } from '~/lib/utils/url_utility';
import { i18n, PAGE_SIZE, DEFAULT_SORT } from '~/releases/constants';
import { convertAllReleasesGraphQLResponse } from '~/releases/util';
import { popDeleteReleaseNotification } from '~/releases/release_notification_service';

import allReleasesQuery from '../graphql/queries/all_releases.query.graphql';

import ReleaseBlock from './release_block.vue';
import ReleaseSkeletonLoader from './release_skeleton_loader.vue';
import ReleasesEmptyState from './releases_empty_state.vue';
import ReleasesPagination from './releases_pagination.vue';
import ReleasesSort from './releases_sort.vue';
import CiCdCatalogWrapper from './ci_cd_catalog_wrapper.vue';

export default {
  name: 'ReleasesIndexApp',
  i18n,
  links: {
    alertInfoMessageLink: helpPagePath('ci/yaml/_index.html', { anchor: 'release' }),
    alertInfoPublishLink: helpPagePath('ci/components/_index', { anchor: 'publish-a-new-release' }),
  },
  components: {
    CiCdCatalogWrapper,
    GlAlert,
    GlButton,
    GlLink,
    GlSprintf,
    ReleaseBlock,
    ReleaseSkeletonLoader,
    ReleasesEmptyState,
    ReleasesPagination,
    ReleasesSort,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    projectPath: {
      default: '',
    },
    newReleasePath: {
      default: '',
    },
    atomFeedPath: {
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
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
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
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
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

        createAlert({
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
    atomFeedBtnTitle() {
      return this.$options.i18n.atomFeedBtnTitle;
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
  mounted() {
    popDeleteReleaseNotification(this.projectPath);
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
    releaseBtnTitle(isCiCdCatalogProject) {
      return isCiCdCatalogProject
        ? this.$options.i18n.catalogResourceReleaseBtnTitle
        : this.$options.i18n.defaultReleaseBtnTitle;
    },
  },
};
</script>
<template>
  <div class="gl-mt-3 gl-flex gl-flex-col">
    <ci-cd-catalog-wrapper>
      <template #default="{ isCiCdCatalogProject }">
        <gl-alert
          v-if="isCiCdCatalogProject"
          :title="$options.i18n.alertTitle"
          :dismissible="false"
          variant="warning"
          class="mb-3 mt-2"
        >
          <gl-sprintf :message="$options.i18n.alertInfoMessage">
            <template #link="{ content }">
              <gl-link
                :href="$options.links.alertInfoMessageLink"
                target="_blank"
                class="gl-mr-2 !gl-no-underline"
              >
                <code class="gl-pr-0">
                  {{ content }}
                </code>
              </gl-link>
            </template>
          </gl-sprintf>
          <gl-link :href="$options.links.alertInfoPublishLink" target="_blank">
            {{ $options.i18n.alertInfoPublishMessage }}
          </gl-link>
        </gl-alert>
      </template>
    </ci-cd-catalog-wrapper>
    <releases-empty-state v-if="shouldRenderEmptyState" />
    <div v-else class="gl-flex gl-gap-3 gl-self-end">
      <releases-sort :value="sort" @input="onSortChanged" />

      <gl-button
        v-if="atomFeedPath"
        v-gl-tooltip.hover
        :title="atomFeedBtnTitle"
        :href="atomFeedPath"
        icon="rss"
        class="gl-ml-2"
        data-testid="atom-feed-btn"
        :aria-label="atomFeedBtnTitle"
      />

      <ci-cd-catalog-wrapper>
        <template #default="{ isCiCdCatalogProject }">
          <div
            v-if="newReleasePath"
            v-gl-tooltip.hover
            :title="releaseBtnTitle(isCiCdCatalogProject)"
            data-testid="new-release-btn-tooltip"
          >
            <gl-button
              :disabled="isCiCdCatalogProject"
              :href="newReleasePath"
              class="gl-ml-2"
              category="primary"
              variant="confirm"
              >{{ $options.i18n.newRelease }}</gl-button
            >
          </div>
        </template>
      </ci-cd-catalog-wrapper>
    </div>

    <release-block
      v-for="(release, index) in releases"
      :key="getReleaseKey(release, index)"
      :release="release"
      :sort="sort"
    />

    <release-skeleton-loader v-if="shouldRenderLoadingIndicator" class="gl-mt-5" />

    <releases-pagination
      v-if="shouldRenderPagination"
      :page-info="pageInfo"
      @prev="onPaginationButtonPress"
      @next="onPaginationButtonPress"
    />
  </div>
</template>
