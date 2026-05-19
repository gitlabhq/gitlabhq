<script>
import {
  GlAvatarLabeled,
  GlButton,
  GlDisclosureDropdown,
  GlEmptyState,
  GlKeysetPagination,
  GlLoadingIcon,
  GlModal,
  GlSprintf,
} from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import { logError } from '~/lib/logger';
import { getFirstPropertyValue } from '~/lib/utils/common_utils';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import { NEW_ROUTE_NAME, EDIT_ROUTE_NAME } from '../constants';
import getGroupAchievements from './graphql/get_group_achievements.query.graphql';
import getMoreUniqueUsers from './graphql/get_more_unique_users.query.graphql';
import deleteAchievementMutation from './graphql/delete_achievement.mutation.graphql';
import AwardButton from './award_button.vue';

const ENTRIES_PER_PAGE = 20;

export default {
  name: 'AchievementsApp',
  components: {
    AwardButton,
    PageHeading,
    CrudComponent,
    GlAvatarLabeled,
    GlButton,
    GlDisclosureDropdown,
    GlEmptyState,
    GlKeysetPagination,
    GlLoadingIcon,
    GlModal,
    GlSprintf,
    UserAvatarList,
  },
  inject: {
    canAdminAchievement: {
      type: Boolean,
      required: true,
    },
    canAwardAchievement: {
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
      achievementToDelete: null,
      showDeleteModal: false,
      cursor: {
        first: ENTRIES_PER_PAGE,
        after: null,
        last: null,
        before: null,
      },
      pageInfo: {},
      loadingUsers: {},
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
    deleteModalTitle() {
      if (!this.achievementToDelete) return '';
      return sprintf(s__('Achievements|Delete %{name}?'), {
        name: this.achievementToDelete.name,
      });
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
    awardedUsers(userCount) {
      return sprintf(
        this.$options.i18n.users,
        {
          userCount,
        },
        false,
      );
    },
    async loadMoreUsers(achievementId, after) {
      this.setLoadingState(achievementId, true);
      try {
        const fetchedData = await this.fetchMoreUniqueUsers(achievementId, after);
        if (fetchedData) {
          this.mergeUniqueUsers(achievementId, fetchedData);
        }
      } finally {
        this.setLoadingState(achievementId, false);
      }
    },
    async fetchMoreUniqueUsers(achievementId, after) {
      const { data } = await this.$apollo.query({
        query: getMoreUniqueUsers,
        variables: {
          groupFullPath: this.groupFullPath,
          achievementId,
          after,
        },
      });
      return data?.group?.achievements?.nodes?.[0]?.uniqueUsers;
    },
    mergeUniqueUsers(achievementId, fetchedData) {
      this.achievements = this.achievements.map((achievement) => {
        if (achievement.id === achievementId) {
          return {
            ...achievement,
            uniqueUsers: {
              nodes: [...achievement.uniqueUsers.nodes, ...fetchedData.nodes],
              pageInfo: fetchedData.pageInfo,
              count: fetchedData.count,
            },
          };
        }
        return achievement;
      });
    },
    setLoadingState(achievementId, isLoading) {
      this.loadingUsers = {
        ...this.loadingUsers,
        [achievementId]: isLoading,
      };
    },
    achievementActions(achievement) {
      return [
        {
          text: s__('Achievements|Edit achievement'),
          action: () => {
            this.$refs[`dropdown-${achievement.id}`]?.[0]?.close();
            this.$router.push({
              name: this.$options.EDIT_ROUTE_NAME,
              params: { id: getIdFromGraphQLId(achievement.id) },
            });
          },
        },
        {
          text: s__('Achievements|Delete achievement'),
          variant: 'danger',
          action: () => {
            this.achievementToDelete = achievement;
            this.showDeleteModal = true;
          },
        },
      ];
    },
    async confirmDelete() {
      const achievement = this.achievementToDelete;
      if (!achievement) return;

      try {
        const { data } = await this.$apollo.mutate({
          mutation: deleteAchievementMutation,
          variables: {
            input: { achievementId: achievement.id },
          },
          refetchQueries: [getGroupAchievements],
        });

        const { errors } = getFirstPropertyValue(data);
        if (errors?.length) {
          this.$toast.show(errors[0]);
        } else {
          this.$toast.show(s__('Achievements|Achievement has been deleted.'));
        }
      } catch (e) {
        logError(e);
        this.$toast.show(s__('Achievements|Failed to delete achievement. Please try again.'));
      } finally {
        this.achievementToDelete = null;
        this.showDeleteModal = false;
      }
    },
  },
  i18n: {
    title: s__('Achievements|Achievements'),
    emptyStateTitle: s__('Achievements|There are currently no achievements.'),
    newAchievement: s__('Achievements|New achievement'),
    notYetAwarded: s__('Achievements|Not yet awarded.'),
    users: s__('Achievements|%{userCount} awarded users'),
    moreActions: s__('Achievements|More actions'),
    deleteModalBody: s__(
      'Achievements|Are you sure you want to delete %{name}? This action cannot be undone.',
    ),
  },
  NEW_ROUTE_NAME,
  EDIT_ROUTE_NAME,
  deleteModal: {
    actionPrimary: {
      text: s__('Achievements|Delete achievement'),
      attributes: { variant: 'danger' },
    },
    actionCancel: {
      text: s__('Achievements|Cancel'),
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-flex-col">
    <gl-modal
      v-model="showDeleteModal"
      modal-id="delete-achievement-modal"
      :title="deleteModalTitle"
      :action-primary="$options.deleteModal.actionPrimary"
      :action-cancel="$options.deleteModal.actionCancel"
      @primary="confirmDelete"
      @canceled="achievementToDelete = null"
    >
      <gl-sprintf v-if="achievementToDelete" :message="$options.i18n.deleteModalBody">
        <template #name>
          <strong>{{ achievementToDelete.name }}</strong>
        </template>
      </gl-sprintf>
    </gl-modal>
    <gl-empty-state
      v-if="!isLoading && !achievements.length"
      :title="$options.i18n.emptyStateTitle"
      illustration-name="empty-search-md"
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
        <template #actions>
          <award-button
            v-if="canAwardAchievement"
            :achievement-id="achievement.id"
            :achievement-name="achievement.name"
          />
          <gl-disclosure-dropdown
            v-if="canAdminAchievement"
            :ref="`dropdown-${achievement.id}`"
            icon="ellipsis_v"
            category="tertiary"
            no-caret
            :toggle-text="$options.i18n.moreActions"
            text-sr-only
            :items="achievementActions(achievement)"
            data-testid="achievement-actions-dropdown"
          />
        </template>
        <div class="mb-2 gl-text-sm gl-text-subtle">
          {{ awardedUsers(achievement.uniqueUsers.count) }}
        </div>
        <user-avatar-list
          v-if="achievement.uniqueUsers.count > 0"
          :items="achievement.uniqueUsers.nodes"
          :img-size="24"
          :has-more="achievement.uniqueUsers.pageInfo.hasNextPage"
          :is-loading="loadingUsers[achievement.id]"
          @load-more="loadMoreUsers(achievement.id, achievement.uniqueUsers.pageInfo.endCursor)"
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
