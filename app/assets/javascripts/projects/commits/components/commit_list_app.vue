<script>
import { GlIcon, GlLoadingIcon } from '@gitlab/ui';
import { localeDateFormat } from '~/lib/utils/datetime_utility';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import {
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_MESSAGE,
  FILTERED_SEARCH_TERM,
} from '~/vue_shared/components/filtered_search_bar/constants';
import commitsQuery from '../graphql/queries/commits.query.graphql';
import { groupCommitsByDay } from '../utils';
import CommitListHeader from './commit_list_header.vue';
import CommitListItem from './commit_list_item.vue';

const COMMITS_PER_PAGE = 20; // Note: this will be user configurable in future (see issue #555379)

export default {
  name: 'CommitListApp',
  components: {
    GlIcon,
    GlLoadingIcon,
    CommitListHeader,
    CommitListItem,
  },
  inject: ['projectFullPath', 'escapedRef'],
  data() {
    return {
      commits: [],
      authorFilter: null,
      messageFilter: null,
    };
  },
  apollo: {
    commits: {
      query: commitsQuery,
      variables() {
        return {
          projectPath: this.projectFullPath,
          ref: this.escapedRef,
          first: COMMITS_PER_PAGE,
          author: this.authorFilter,
          query: this.messageFilter,
        };
      },
      update(data) {
        return data.project?.repository?.commits?.nodes || [];
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
    </template>

    <p v-else class="gl-mt-5 gl-text-center gl-text-subtle">
      {{ s__('Commits|No commits found') }}
    </p>
  </div>
</template>
