<script>
import { GlEmptyState, GlKeysetPagination, GlLoadingIcon, GlTableLite } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { s__ } from '~/locale';
import getGroupAchievements from './graphql/get_group_achievements.query.graphql';

const ENTRIES_PER_PAGE = 20;

export default {
  components: {
    GlEmptyState,
    GlKeysetPagination,
    GlLoadingIcon,
    GlTableLite,
  },
  inject: {
    groupFullPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      achievements: [],
      cursor: {
        first: ENTRIES_PER_PAGE,
        after: null,
        last: null,
        before: null,
      },
      pageInfo: {},
    };
  },
  apollo: {
    achievements: {
      query: getGroupAchievements,
      variables() {
        return {
          groupFullPath: this.groupFullPath,
          ...this.cursor,
        };
      },
      result({ data }) {
        this.pageInfo = data?.group?.achievements?.pageInfo;
      },
      update(data) {
        return data?.group?.achievements?.nodes || [];
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.achievements.loading;
    },
    items() {
      return this.achievements.map((achievement) => ({
        id: getIdFromGraphQLId(achievement.id),
        name: achievement.name,
        description: achievement.description,
      }));
    },
    showPagination() {
      return this.pageInfo?.hasPreviousPage || this.pageInfo?.hasNextPage;
    },
  },
  methods: {
    nextPage(item) {
      this.cursor = {
        first: ENTRIES_PER_PAGE,
        after: item,
        last: null,
        before: null,
      };
    },
    prevPage(item) {
      this.cursor = {
        first: null,
        after: null,
        last: ENTRIES_PER_PAGE,
        before: item,
      };
    },
  },
  i18n: {
    emptyStateTitle: s__('Achievements|There are currently no achievements.'),
  },
};
</script>

<template>
  <div class="gl-display-flex gl-flex-direction-column">
    <gl-loading-icon v-if="isLoading" size="lg" class="gl-mt-5" />
    <gl-empty-state v-else-if="!items.length" :title="$options.i18n.emptyStateTitle" />
    <template v-else>
      <gl-table-lite :items="items" />
      <gl-keyset-pagination
        v-if="showPagination"
        v-bind="pageInfo"
        class="gl-mt-3 gl-align-self-center"
        @prev="prevPage"
        @next="nextPage"
      />
    </template>
  </div>
</template>
