<script>
import { GlIcon, GlKeysetPagination, GlLoadingIcon } from '@gitlab/ui';
import { localeDateFormat } from '~/lib/utils/datetime_utility';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import {
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_MESSAGE,
  FILTERED_SEARCH_TERM,
} from '~/vue_shared/components/filtered_search_bar/constants';
import PageSizeSelector from '~/vue_shared/components/page_size_selector.vue';
import commitsQuery from '../graphql/queries/commits.query.graphql';
import { groupCommitsByDay } from '../utils';
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
  inject: ['projectFullPath', 'escapedRef'],
  data() {
    return {
      commits: [],
      pageInfo: {},
      authorFilter: null,
      messageFilter: null,
      pageSize: DEFAULT_PAGE_SIZE,
      cursors: [],
      currentCursor: null,
    };
  },
  apollo: {
    commits: {
      query: commitsQuery,
      variables() {
        return {
          projectPath: this.projectFullPath,
          ref: this.escapedRef,
          first: this.pageSize,
          after: this.currentCursor,
          author: this.authorFilter,
          query: this.messageFilter,
        };
      },
      update(data) {
        return data.project?.repository?.commits?.nodes || [];
      },
      result({ data }) {
        this.pageInfo = data?.project?.repository?.commits?.pageInfo || {};
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
  methods: {
    getFormattedDate(dateTime) {
      return localeDateFormat.asDate.format(new Date(dateTime));
    },
    handleFilter(filters) {
      const filterMap = {
        [TOKEN_TYPE_AUTHOR]: 'authorFilter',
        [TOKEN_TYPE_MESSAGE]: 'messageFilter',
        [FILTERED_SEARCH_TERM]: 'messageFilter',
      };

      const result = { authorFilter: null, messageFilter: null };

      filters.forEach((filter) => {
        const key = filterMap[filter.type];
        if (key && filter.value?.data) {
          result[key] = filter.value.data;
        }
      });

      Object.assign(this, result);
      this.resetPagination();
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
    },
  },
};
</script>

<template>
  <div class="gl-mt-5">
    <commit-list-header @filter="handleFilter" />

    <gl-loading-icon v-if="isLoading" size="md" class="gl-mt-5" />

    <template v-else-if="groupedCommits.length">
      <ol class="gl-my-5 gl-list-none gl-p-0">
        <li v-for="group in groupedCommits" :key="group.day" data-testid="daily-commits">
          <h2 class="gl-mb-5 gl-flex gl-items-center gl-gap-3 gl-text-base @md/panel:gl-gap-5">
            <gl-icon name="commit" />
            <time class="gl-font-bold" :datetime="group.day">
              {{ getFormattedDate(group.day) }}
            </time>
          </h2>
          <ul class="daily-commits-item gl-mb-6 gl-list-none gl-p-0">
            <commit-list-item v-for="commit in group.commits" :key="commit.id" :commit="commit" />
          </ul>
        </li>
      </ol>

      <div v-if="showPagination" class="gl-mt-4 gl-flex gl-items-center gl-justify-between">
        <div></div>
        <gl-keyset-pagination
          :has-previous-page="hasPreviousPage"
          :has-next-page="pageInfo.hasNextPage"
          @prev="prevPage"
          @next="nextPage"
        />
        <page-size-selector :value="pageSize" @input="handlePageSizeChange" />
      </div>
    </template>

    <p v-else class="gl-mt-5 gl-text-center gl-text-subtle">
      {{ s__('Commits|No commits found') }}
    </p>
  </div>
</template>
