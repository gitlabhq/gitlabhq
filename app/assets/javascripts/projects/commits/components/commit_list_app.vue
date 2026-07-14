<script>
import { GlKeysetPagination, GlLoadingIcon, GlIcon } from '@gitlab/ui';
import { InternalEvents } from '~/tracking';
import { isValidDate, localeDateFormat, newDate } from '~/lib/utils/datetime_utility';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import {
  FILTERED_SEARCH_TERM,
  OPERATOR_IS,
} from '~/vue_shared/components/filtered_search_bar/constants';
import {
  filterToQueryObject,
  processFilters,
  urlQueryToFilter,
  prepareTokens,
} from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import PageSizeSelector from '~/vue_shared/components/page_size_selector.vue';
import { performanceMarkAndMeasure } from '~/performance/utils';
import {
  COMMIT_LIST_MARK_APP_MOUNTED,
  COMMIT_LIST_MARK_FETCHING_DATA,
  COMMIT_LIST_MARK_RENDERING_DATA,
  COMMIT_LIST_MARK_DATA_RENDERED,
  COMMIT_LIST_MEASURE_TIME_TO_MOUNT,
  COMMIT_LIST_MEASURE_DATA_FETCH,
  COMMIT_LIST_MEASURE_RENDER,
} from '~/performance/constants';
import { safeDecodeURIComponent } from '~/lib/utils/url_utility';
import { extractFirstPathSegment } from '~/repository/utils/url_utility';
import commitsQuery from '../graphql/queries/commits.query.graphql';
import { groupCommitsByDay } from '../utils/commit_grouping';
import CommitListHeader from './commit_list_header.vue';
import CommitListItem from './commit_list_item.vue';

const DEFAULT_PAGE_SIZE = 20;

export default {
  name: 'CommitListApp',
  components: {
    GlIcon,
    GlKeysetPagination,
    GlLoadingIcon,
    PageSizeSelector,
    CommitListHeader,
    CommitListItem,
  },
  mixins: [InternalEvents.mixin()],
  inject: ['projectFullPath', 'escapedRef'],
  data() {
    return {
      commits: [],
      pageInfo: {},
      authorFilter: null,
      messageFilter: null,
      committedAfterFilter: null,
      committedBeforeFilter: null,
      pageSize: DEFAULT_PAGE_SIZE,
      cursors: [],
      currentCursor: null,
      currentRef: decodeURIComponent(this.escapedRef),
      currentPath: null,
      initialFilterTokens: [],
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.commits.loading;
    },
    groupedCommits() {
      return groupCommitsByDay(this.commits);
    },
    showPagination() {
      return this.pageInfo.hasNextPage || this.hasPreviousPage;
    },
    hasPreviousPage() {
      return this.cursors.length > 0;
    },
  },
  watch: {
    $route(newRoute) {
      const refChanged = this.syncRefFromRoute(newRoute);
      const pathChanged = this.syncPathFromRoute(newRoute);
      const filtersChanged = this.syncFiltersFromRoute(newRoute);

      if (refChanged || pathChanged || filtersChanged) {
        this.resetPagination();
      }
    },
  },
  apollo: {
    commits: {
      query: commitsQuery,
      variables() {
        return {
          projectPath: this.projectFullPath,
          ref: this.currentRef,
          first: this.pageSize,
          after: this.currentCursor,
          author: this.authorFilter,
          query: this.messageFilter,
          path: this.currentPath,
          committedAfter: this.committedAfterFilter,
          committedBefore: this.committedBeforeFilter,
        };
      },
      watchLoading(isLoading) {
        if (isLoading) {
          performanceMarkAndMeasure({
            mark: COMMIT_LIST_MARK_FETCHING_DATA,
          });
        }
      },
      update(data) {
        return data.project?.repository?.commits?.nodes || [];
      },
      result({ data }) {
        this.pageInfo = data?.project?.repository?.commits?.pageInfo || {};

        if (performance.getEntriesByName(COMMIT_LIST_MARK_RENDERING_DATA).length) return;

        // Use performance.mark/measure directly instead of performanceMarkAndMeasure
        // because the utility defers execution via requestAnimationFrame. The mark must
        // exist synchronously so the measure on the next line can reference it, and so
        // the $nextTick callback below can reliably compute the render duration from it.
        performance.mark(COMMIT_LIST_MARK_RENDERING_DATA);
        performance.measure(
          COMMIT_LIST_MEASURE_DATA_FETCH,
          COMMIT_LIST_MARK_FETCHING_DATA,
          COMMIT_LIST_MARK_RENDERING_DATA,
        );

        this.$nextTick(() => {
          performanceMarkAndMeasure({
            mark: COMMIT_LIST_MARK_DATA_RENDERED,
            measures: [
              {
                name: COMMIT_LIST_MEASURE_RENDER,
                start: COMMIT_LIST_MARK_RENDERING_DATA,
                end: COMMIT_LIST_MARK_DATA_RENDERED,
              },
            ],
          });
        });
      },
      error(error) {
        createAlert({
          message:
            error.message ||
            s__('Commits|Something went wrong while loading commits. Please try again.'),
          captureError: true,
          error,
        });
      },
    },
  },
  created() {
    this.syncRefFromRoute(this.$route);
    this.syncPathFromRoute(this.$route);
    this.syncFiltersFromRoute(this.$route);
  },
  mounted() {
    performanceMarkAndMeasure({
      mark: COMMIT_LIST_MARK_APP_MOUNTED,
      measures: [
        {
          name: COMMIT_LIST_MEASURE_TIME_TO_MOUNT,
        },
      ],
    });
  },
  methods: {
    getFormattedDate(dateTime) {
      const date = newDate(dateTime);
      return isValidDate(date) ? localeDateFormat.asDate.format(date) : dateTime;
    },
    syncRefFromRoute(route) {
      // The static routes ('commitsPath' / 'commitsPathDecoded') are
      // hardcoded to the initial ref.  For refs containing '/' the route
      // path has literal slashes, so extractFirstPathSegment would split
      // incorrectly.  Use the injected escapedRef which is always the
      // correct, complete ref for these routes.
      if (
        route.name === 'commitsPath' ||
        route.name === 'commitsPathDecoded' ||
        route.name === 'commitsPathEncoded'
      ) {
        const newRef = decodeURIComponent(this.escapedRef);
        if (this.currentRef === newRef) return false;
        this.currentRef = newRef;
        return true;
      }

      // The wildcard fallback ('commitsAnyRef') fires after an in-app ref
      // switch and during browser back/forward navigation.  The ref is
      // encoded with encodeURIComponent (slashes become %2F), so
      // route.params.ref is a single, unambiguous segment.  Vue Router
      // auto-decodes params, so the value is already the full ref name.
      if (route.name === 'commitsAnyRef') {
        const newRef = route.params.ref || decodeURIComponent(this.escapedRef);
        if (this.currentRef === newRef) return false;
        this.currentRef = newRef;
        return true;
      }

      // Unknown or unnamed route — best-effort extraction from the path.
      const refSegment = extractFirstPathSegment(route.path);
      const newRef = refSegment
        ? safeDecodeURIComponent(refSegment)
        : decodeURIComponent(this.escapedRef);

      if (this.currentRef === newRef) return false;
      this.currentRef = newRef;
      return true;
    },
    syncPathFromRoute(route) {
      const rawPath = route.params?.path;
      const normalizedPath = Array.isArray(rawPath) ? rawPath.join('/') : rawPath || null;
      if (this.currentPath === normalizedPath) return false;
      this.currentPath = normalizedPath;
      return true;
    },
    syncFiltersFromRoute(route) {
      const filters = urlQueryToFilter(route.query, {
        filterNamesAllowList: ['author', 'message', 'committed_after', 'committed_before'],
      });
      const author = filters.author?.value || null;
      const message = filters.message?.value || null;
      const committedAfter = filters.committed_after?.value || null;
      const committedBefore = filters.committed_before?.value || null;
      const pageSize = parseInt(route.query.page_size, 10) || DEFAULT_PAGE_SIZE;

      if (
        this.authorFilter === author &&
        this.messageFilter === message &&
        this.committedAfterFilter === committedAfter &&
        this.committedBeforeFilter === committedBefore &&
        this.pageSize === pageSize
      ) {
        return false;
      }

      this.applyFiltersFromRoute(filters, route.query);
      return true;
    },
    handleRefChange(newRef) {
      this.currentRef = newRef;
      this.resetPagination();
    },
    applyFiltersFromRoute(filters, query) {
      this.authorFilter = filters.author?.value || null;
      this.messageFilter = filters.message?.value || null;
      this.committedAfterFilter = filters.committed_after?.value || null;
      this.committedBeforeFilter = filters.committed_before?.value || null;
      this.pageSize = parseInt(query.page_size, 10) || DEFAULT_PAGE_SIZE;
      // Map URL param names to token type names for the filtered search bar
      const tokenFilters = {
        ...filters,
        'committed-after': filters.committed_after,
        'committed-before': filters.committed_before,
      };
      delete tokenFilters.committed_after;
      delete tokenFilters.committed_before;
      this.initialFilterTokens = prepareTokens(tokenFilters);
    },
    handleFilter(filters) {
      const processed = processFilters(filters);
      this.authorFilter = processed.author?.[0]?.value || null;
      this.messageFilter =
        processed.message?.[0]?.value || processed[FILTERED_SEARCH_TERM]?.[0]?.value || null;
      this.committedAfterFilter = processed['committed-after']?.[0]?.value || null;
      this.committedBeforeFilter = processed['committed-before']?.[0]?.value || null;

      const activeFilters = [];
      if (this.authorFilter) activeFilters.push('author');
      if (this.messageFilter) activeFilters.push('message');
      if (this.committedAfterFilter) activeFilters.push('committed-after');
      if (this.committedBeforeFilter) activeFilters.push('committed-before');
      this.trackEvent('filter_commit_list', { label: activeFilters.join(',') || 'none' });

      this.resetPagination();
      this.updateUrl();
    },
    resetPagination() {
      this.cursors = [];
      this.currentCursor = null;
    },
    nextPage() {
      this.cursors.push(this.currentCursor);
      this.currentCursor = this.pageInfo.endCursor;
    },
    prevPage() {
      this.currentCursor = this.cursors.pop() ?? null;
    },
    handlePageSizeChange(size) {
      this.pageSize = size;
      this.resetPagination();
      this.updateUrl();
    },
    updateUrl() {
      const filterObj = {};
      if (this.authorFilter) filterObj.author = { value: this.authorFilter, operator: OPERATOR_IS };
      if (this.messageFilter)
        filterObj.message = { value: this.messageFilter, operator: OPERATOR_IS };
      if (this.committedAfterFilter)
        filterObj.committed_after = { value: this.committedAfterFilter, operator: OPERATOR_IS };
      if (this.committedBeforeFilter)
        filterObj.committed_before = { value: this.committedBeforeFilter, operator: OPERATOR_IS };
      const query = {
        ...filterToQueryObject(filterObj, { shouldExcludeEmpty: true }),
        ...(this.pageSize !== DEFAULT_PAGE_SIZE ? { page_size: String(this.pageSize) } : {}),
      };

      if (JSON.stringify(this.$route.query) !== JSON.stringify(query)) {
        this.$router.push({ query }).catch((error) => {
          if (error.name !== 'NavigationDuplicated') {
            throw error;
          }
        });
      }
    },
  },
};
</script>

<template>
  <div class="gl-mt-5 gl-@container/panel">
    <commit-list-header
      :file-path="currentPath"
      :current-ref="currentRef"
      :initial-filter-tokens="initialFilterTokens"
      @filter="handleFilter"
      @ref-change="handleRefChange"
    />

    <gl-loading-icon v-if="isLoading" size="md" class="gl-mt-5" />

    <template v-else-if="groupedCommits.length">
      <ol class="gl-my-5 gl-list-none gl-p-0">
        <li
          v-for="group in groupedCommits"
          :key="group.day"
          class="daily-commit"
          data-testid="daily-commits"
        >
          <h2 class="gl-mb-5 gl-flex gl-items-center gl-gap-3 gl-text-base @md/panel:gl-gap-5">
            <gl-icon name="commit" />
            <time class="gl-font-bold" :datetime="group.day">
              {{ getFormattedDate(group.day) }}
            </time>
          </h2>
          <ul class="daily-commits-item gl-mb-6 gl-flex gl-list-none gl-flex-col gl-gap-3 gl-p-0">
            <commit-list-item v-for="commit in group.commits" :key="commit.id" :commit="commit" />
          </ul>
        </li>
      </ol>

      <div
        class="gl-relative gl-mt-4 gl-flex"
        :class="showPagination ? 'gl-justify-center' : 'gl-justify-end'"
      >
        <gl-keyset-pagination
          v-if="showPagination"
          :has-previous-page="hasPreviousPage"
          :has-next-page="pageInfo.hasNextPage"
          @prev="prevPage"
          @next="nextPage"
        />
        <page-size-selector
          :value="pageSize"
          :class="showPagination ? 'gl-absolute gl-right-0' : ''"
          @input="handlePageSizeChange"
        />
      </div>
    </template>

    <p v-else class="gl-mt-5 gl-text-center gl-text-subtle">
      {{ s__('Commits|No commits found') }}
    </p>
  </div>
</template>
