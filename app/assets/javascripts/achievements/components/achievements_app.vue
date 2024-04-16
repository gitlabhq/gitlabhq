<script>
import {
  GlAvatarLabeled,
  GlButton,
  GlCard,
  GlEmptyState,
  GlKeysetPagination,
  GlLoadingIcon,
} from '@gitlab/ui';
import { uniqBy } from 'lodash';
import { s__ } from '~/locale';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import { NEW_ROUTE_NAME } from '../constants';
import getGroupAchievements from './graphql/get_group_achievements.query.graphql';

const ENTRIES_PER_PAGE = 20;

export default {
  components: {
    GlAvatarLabeled,
    GlButton,
    GlCard,
    GlEmptyState,
    GlKeysetPagination,
    GlLoadingIcon,
    UserAvatarList,
  },
  inject: {
    canAdminAchievement: {
      type: Boolean,
      required: true,
    },
    gitlabLogoPath: {
      type: String,
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
    uniqueRecipients(userAchievements) {
      return uniqBy(userAchievements, 'user.id').map(({ user }) => user);
    },
  },
  i18n: {
    emptyStateTitle: s__('Achievements|There are currently no achievements.'),
    newAchievement: s__('Achievements|New achievement'),
    notYetAwarded: s__('Achievements|Not yet awarded.'),
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
    <gl-empty-state v-else-if="!achievements.length" :title="$options.i18n.emptyStateTitle" />
    <template v-else>
      <gl-card
        v-for="achievement in achievements"
        :key="achievement.id"
        body-class="gl-p-3"
        footer-class="gl-p-3 gl-new-card-empty"
        class="gl-mb-5"
      >
        <gl-avatar-labeled
          shape="rect"
          :size="64"
          :src="achievement.avatarUrl || gitlabLogoPath"
          :label="achievement.name"
          :sub-label="achievement.description"
        />
        <template #footer>
          <user-avatar-list
            v-if="achievement.userAchievements.nodes.length"
            :items="uniqueRecipients(achievement.userAchievements.nodes)"
            :img-size="24"
          />
          <span v-else>{{ $options.i18n.notYetAwarded }}</span>
        </template>
      </gl-card>
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
