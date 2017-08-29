<script>
import userAvatarLink from '../../vue_shared/components/user_avatar/user_avatar_link.vue';
import timeAgoTooltip from '../../vue_shared/components/time_ago_tooltip.vue';

export default {
  name: 'repo-file-last-commit',
  components: {
    userAvatarLink,
    timeAgoTooltip,
  },
  props: {
    auxiliary: {
      type: String,
      required: true,
    },
    lastCommit: {
      type: Object,
      required: true,
    }
  },
  computed: {
    committerProfileUrl() {
      // TODO: Get from backend
      return '/root';
    },
    committerAvatarUrl() {
      // TODO: Get from backend
      return 'http://www.gravatar.com/avatar/d30c6eb41f9082697c13b5bc35b89cc2?s=48&d=identicon';
    },
    committerAvatarAlt() {
      return `${this.lastCommit.committer_name}'s avatar`;
    },
    commitUrl() {
      // TODO: Get from backend
      return "/gitlab-org/gitlab-ce/commit/6f0f65becbbe968bd26a5a3872044d7b8633bf2e";
    },
  },
};
</script>

<template>
  <div class="last-commit-container">
    <div class="commit flex-row">
      <user-avatar-link
        :link-href="committerProfileUrl"
        :img-src="committerAvatarUrl"
        :img-alt="committerAvatarAlt"
        :img-size="36"
        :tooltip-text="lastCommit.committer_name"
        tooltip-placement="bottom"
      />
      <div class="commit-detail">
        <div class="commit-content">
          <a class="item-title" :href="commitUrl">{{lastCommit.message}}</a>
          <div>
            <a class="commit-author-link has-tooltip" :href="committerProfileUrl" :data-original-title="lastCommit.committer_email">{{lastCommit.committer_name}}</a> committed
            <time-ago-tooltip
              tooltipPlacement="bottom"
              :time="lastCommit.committed_date"
            />
          </div>
        </div>
      </div>
    </div>
    <div v-html="auxiliary" />
  </div>
</template>
