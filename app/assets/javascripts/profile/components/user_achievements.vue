<script>
import { GlPopover, GlSprintf } from '@gitlab/ui';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { s__ } from '~/locale';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import getUserAchievements from './graphql/get_user_achievements.query.graphql';

export default {
  name: 'UserAchievements',
  components: { GlPopover, GlSprintf },
  mixins: [timeagoMixin],
  inject: ['rootUrl', 'userId'],
  apollo: {
    userAchievements: {
      query: getUserAchievements,
      variables() {
        return {
          id: convertToGraphQLId(TYPENAME_USER, this.userId),
        };
      },
      update(data) {
        return this.processNodes(data.user.userAchievements.nodes);
      },
      error() {
        return [];
      },
    },
  },
  methods: {
    processNodes(nodes) {
      return nodes.slice(0, 3).map(({ achievement, createdAt, achievement: { namespace } }) => {
        return {
          id: `user-achievement-${getIdFromGraphQLId(achievement.id)}`,
          name: achievement.name,
          timeAgo: this.timeFormatted(createdAt),
          avatarUrl: achievement.avatarUrl || gon.gitlab_logo,
          description: achievement.description,
          namespace: namespace && {
            fullPath: namespace.fullPath,
            webUrl: this.rootUrl + namespace.fullPath,
          },
        };
      });
    },
    achievementAwardedMessage(userAchievement) {
      return userAchievement.namespace
        ? this.$options.i18n.awardedBy
        : this.$options.i18n.awardedByUnknownNamespace;
    },
  },
  i18n: {
    awardedBy: s__('Achievements|Awarded %{timeAgo} by %{namespace}'),
    awardedByUnknownNamespace: s__('Achievements|Awarded %{timeAgo} by a private namespace'),
  },
};
</script>

<template>
  <div class="gl-mb-3">
    <div
      v-for="userAchievement in userAchievements"
      :key="userAchievement.id"
      class="gl-display-inline-block"
      data-testid="user-achievement"
    >
      <img
        :id="userAchievement.id"
        :src="userAchievement.avatarUrl"
        :alt="''"
        tabindex="0"
        class="gl-avatar gl-avatar-s32 gl-mx-2"
      />
      <gl-popover triggers="hover focus" placement="top" :target="userAchievement.id">
        <div class="gl-font-weight-bold">{{ userAchievement.name }}</div>
        <div>
          <gl-sprintf :message="achievementAwardedMessage(userAchievement)">
            <template #timeAgo>
              <span>{{ userAchievement.timeAgo }}</span>
            </template>
            <template v-if="userAchievement.namespace" #namespace>
              <a :href="userAchievement.namespace.webUrl">{{
                userAchievement.namespace.fullPath
              }}</a>
            </template>
          </gl-sprintf>
        </div>
        <div
          v-if="userAchievement.description"
          class="gl-mt-5"
          data-testid="achievement-description"
        >
          {{ userAchievement.description }}
        </div>
      </gl-popover>
    </div>
  </div>
</template>
