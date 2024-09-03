<script>
import { GlAvatar, GlBadge, GlPopover, GlSprintf } from '@gitlab/ui';
import { groupBy } from 'lodash';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { s__ } from '~/locale';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { joinPaths } from '~/lib/utils/url_utility';
import getUserAchievements from './graphql/get_user_achievements.query.graphql';

export default {
  name: 'UserAchievements',
  components: { GlAvatar, GlBadge, GlPopover, GlSprintf },
  mixins: [timeagoMixin],
  inject: ['rootUrl', 'userId'],
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
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
      return Object.entries(groupBy(nodes, 'achievement.id')).map(([id, values]) => {
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
    <h2 class="gl-mb-2 gl-mt-4 gl-text-base">
      {{ $options.i18n.achievementsLabel }}
    </h2>
    <div class="gl-flex gl-flex-wrap gl-gap-3">
      <div
        v-for="userAchievement in userAchievements"
        :key="userAchievement.id"
        class="gl-relative"
        data-testid="user-achievement"
      >
        <gl-avatar
          :id="userAchievement.id"
          :src="userAchievement.avatarUrl"
          :size="48"
          tabindex="0"
          shape="rect"
          class="gl-p-1 gl-outline-none"
        />
        <br />
        <gl-badge
          v-if="showCountBadge(userAchievement.count)"
          class="gl-absolute gl-left-7 gl-top-7 gl-z-1"
          variant="info"
          >{{ getCountBadge(userAchievement.count) }}</gl-badge
        >
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
  </div>
</template>
