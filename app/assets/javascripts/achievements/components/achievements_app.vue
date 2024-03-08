<script>
import { GlButton, GlEmptyState, GlKeysetPagination, GlLoadingIcon, GlTableLite } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { s__ } from '~/locale';
import { NEW_ROUTE_NAME } from '../constants';
import getGroupAchievements from './graphql/get_group_achievements.query.graphql';

const ENTRIES_PER_PAGE = 20;

export default {
  components: {
    GlButton,
    GlEmptyState,
    GlKeysetPagination,
    GlLoadingIcon,
    GlTableLite,
  },
  inject: {
    canAdminAchievement: {
      type: Boolean,
      required: true,
    },
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
        return this.queryVariables;
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
    query() {
      return {
        query: getGroupAchievements,
        variables: this.queryVariables,
      };
    },
    queryVariables() {
      return {
        groupFullPath: this.groupFullPath,
        ...this.cursor,
      };
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
    newAchievement: s__('Achievements|New achievement'),
  },
  NEW_ROUTE_NAME,
};
</script>

<template>
  <div class="gl-display-flex gl-flex-direction-column">
    <router-link v-if="canAdminAchievement" :to="{ name: $options.NEW_ROUTE_NAME }">
      <gl-button variant="confirm" data-testid="new-achievement-button" class="gl-my-3">
        {{ $options.i18n.newAchievement }}
      </gl-button>
    </router-link>
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
    <router-view :store-query="query" />
  </div>
</template>
