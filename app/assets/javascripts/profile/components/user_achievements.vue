<script>
import { GlAvatar, GlBadge, GlPopover, GlSprintf } from '@gitlab/ui';
import { groupBy } from 'lodash';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { s__ } from '~/locale';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { joinPaths } from '~/lib/utils/url_utility';
import getUserAchievements from './graphql/get_user_achievements.query.graphql';

export const MAX_VISIBLE_ACHIEVEMENTS = 7;

export default {
  name: 'UserAchievements',
  components: { GlAvatar, GlBadge, GlPopover, GlSprintf },
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
  computed: {
    hasUserAchievements() {
      return Boolean(this.userAchievements?.length);
    },
  },
  methods: {
    processNodes(nodes) {
      return Object.entries(groupBy(nodes, 'achievement.id'))
        .slice(0, MAX_VISIBLE_ACHIEVEMENTS)
        .map(([id, values]) => {
          const {
            achievement: { name, avatarUrl, description, namespace },
            createdAt,
          } = values[0];
          const count = values.length;
          return {
            id: `user-achievement-${id}`,
            name,
            timeAgo: this.timeFormatted(createdAt),
            avatarUrl: avatarUrl || gon.gitlab_logo,
            description,
            namespace: namespace && {
              fullPath: namespace.fullPath,
              webUrl: joinPaths(this.rootUrl, namespace.achievementsPath),
            },
            count,
          };
        });
    },
    achievementAwardedMessage(userAchievement) {
      return userAchievement.namespace
        ? this.$options.i18n.awardedBy
        : this.$options.i18n.awardedByUnknownNamespace;
    },
    showCountBadge(count) {
      return count > 1;
    },
    getCountBadge(count) {
      return `${count}x`;
    },
  },
  i18n: {
    awardedBy: s__('Achievements|Awarded %{timeAgo} by %{namespace}'),
    awardedByUnknownNamespace: s__('Achievements|Awarded %{timeAgo} by a private namespace'),
    achievementsLabel: s__('Achievements|Achievements'),
  },
};
</script>

<template>
  <div v-if="hasUserAchievements">
    <h2 class="gl-font-base gl-mb-2 gl-mt-4">
      {{ $options.i18n.achievementsLabel }}
    </h2>
    <div
      v-for="userAchievement in userAchievements"
      :key="userAchievement.id"
      class="gl-mr-2 gl-display-inline-block gl-align-top gl-text-center"
      data-testid="user-achievement"
    >
      <gl-avatar
        :id="userAchievement.id"
        :src="userAchievement.avatarUrl"
        :size="32"
        tabindex="0"
        shape="rect"
        class="gl-p-1 gl-border-none"
      />
      <br />
      <gl-badge v-if="showCountBadge(userAchievement.count)" variant="info">{{
        getCountBadge(userAchievement.count)
      }}</gl-badge>
      <gl-popover :target="userAchievement.id">
        <div>
          <span class="gl-font-bold">{{ userAchievement.name }}</span>
          <gl-badge v-if="showCountBadge(userAchievement.count)" variant="info">{{
            getCountBadge(userAchievement.count)
          }}</gl-badge>
        </div>
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
