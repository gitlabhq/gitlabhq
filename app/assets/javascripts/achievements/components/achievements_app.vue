<script>
import FILTERED_SVG_URL from '@gitlab/svgs/dist/illustrations/empty-state/empty-search-md.svg?url';

import {
  GlAvatarLabeled,
  GlButton,
  GlEmptyState,
  GlKeysetPagination,
  GlLoadingIcon,
} from '@gitlab/ui';
import { uniqBy } from 'lodash';
import { s__ } from '~/locale';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import { NEW_ROUTE_NAME } from '../constants';
import getGroupAchievements from './graphql/get_group_achievements.query.graphql';

const ENTRIES_PER_PAGE = 20;

export default {
  components: {
    PageHeading,
    CrudComponent,
    GlAvatarLabeled,
    GlButton,
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
    title: s__('Achievements|Achievements'),
    emptyStateTitle: s__('Achievements|There are currently no achievements.'),
    newAchievement: s__('Achievements|New achievement'),
    notYetAwarded: s__('Achievements|Not yet awarded.'),
  },
  NEW_ROUTE_NAME,
  FILTERED_SVG_URL,
  svgHeight: 145,
};
</script>

<template>
  <div class="gl-flex gl-flex-col">
    <gl-empty-state
      v-if="!isLoading && !achievements.length"
      :title="$options.i18n.emptyStateTitle"
      :svg-path="$options.FILTERED_SVG_URL"
      :svg-height="$options.svgHeight"
    >
      <template #description>
        <router-link v-if="canAdminAchievement" :to="{ name: $options.NEW_ROUTE_NAME }">
          <gl-button variant="confirm" data-testid="new-achievement-button" class="gl-my-3">
            {{ $options.i18n.newAchievement }}
          </gl-button>
        </router-link>
      </template>
    </gl-empty-state>
    <page-heading v-else :heading="$options.i18n.title">
      <template #actions>
        <router-link v-if="canAdminAchievement" :to="{ name: $options.NEW_ROUTE_NAME }">
          <gl-button variant="confirm" data-testid="new-achievement-button" class="gl-my-3">
            {{ $options.i18n.newAchievement }}
          </gl-button>
        </router-link>
      </template>
    </page-heading>
    <gl-loading-icon v-if="isLoading" size="lg" class="gl-mt-5" />
    <template v-else-if="achievements.length">
      <crud-component
        v-for="(achievement, index) in achievements"
        :key="achievement.id"
        :class="{ 'gl-mt-5': index !== 0 }"
      >
        <template #description>
          <gl-avatar-labeled
            shape="rect"
            :size="48"
            :src="achievement.avatarUrl || gitlabLogoPath"
            :label="achievement.name"
            :sub-label="achievement.description"
          />
        </template>

        <user-avatar-list
          v-if="achievement.userAchievements.nodes.length"
          :items="uniqueRecipients(achievement.userAchievements.nodes)"
          :img-size="24"
        />
        <span v-else class="gl-text-subtle">{{ $options.i18n.notYetAwarded }}</span>
      </crud-component>
      <gl-keyset-pagination
        v-if="showPagination"
        v-bind="pageInfo"
        class="gl-mt-3 gl-self-center"
        @prev="prevPage"
        @next="nextPage"
      />
    </template>
    <router-view :store-query="query" />
  </div>
</template>
