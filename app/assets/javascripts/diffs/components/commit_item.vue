<script>
import tooltip from '~/vue_shared/directives/tooltip';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import Icon from '~/vue_shared/components/icon.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import CIIcon from '~/vue_shared/components/ci_icon.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import CommitPipelineStatus from '~/projects/tree/components/commit_pipeline_status_component.vue';

/**
 * CommitItem
 *
 * -----------------------------------------------------------------
 * WARNING: Please keep changes up-to-date with the following files:
 * - `views/projects/commits/_commit.html.haml`
 * -----------------------------------------------------------------
 *
 * This Component was cloned from a HAML view. For the time being they
 * coexist, but there is an issue to remove the duplication.
 * https://gitlab.com/gitlab-org/gitlab-ce/issues/51613
 *
 */
export default {
  directives: {
    tooltip,
  },
  components: {
    UserAvatarLink,
    Icon,
    ClipboardButton,
    CIIcon,
    TimeAgoTooltip,
    CommitPipelineStatus,
  },
  props: {
    commit: {
      type: Object,
      required: true,
    },
  },
  computed: {
    authorName() {
      return (this.commit.author && this.commit.author.name) || this.commit.authorName;
    },
    authorUrl() {
      return (
        (this.commit.author && this.commit.author.webUrl) || `mailto:${this.commit.authorEmail}`
      );
    },
    authorAvatar() {
      return (this.commit.author && this.commit.author.avatarUrl) || this.commit.authorGravatarUrl;
    },
  },
};
</script>

<template>
  <li class="commit flex-row js-toggle-container">
    <user-avatar-link
      :link-href="authorUrl"
      :img-src="authorAvatar"
      :img-alt="authorName"
      :img-size="36"
      class="avatar-cell d-none d-sm-block"
    />
    <div class="commit-detail flex-list">
      <div class="commit-content qa-commit-content">
        <a
          :href="commit.commitUrl"
          class="commit-row-message item-title"
          v-html="commit.titleHtml"
        ></a>

        <span class="commit-row-message d-block d-sm-none">
          &middot;
          {{ commit.shortId }}
        </span>

        <button
          v-if="commit.descriptionHtml"
          class="text-expander js-toggle-button"
          type="button"
          :aria-label="__('Toggle commit description')"
        >
          <icon
            :size="12"
            name="ellipsis_h"
          />
        </button>

        <div class="commiter">
          <a
            :href="authorUrl"
            v-text="authorName"
          ></a>
          {{ s__('CommitWidget|authored') }}
          <time-ago-tooltip
            :time="commit.authoredDate"
          />
        </div>

        <pre
          v-if="commit.descriptionHtml"
          class="commit-row-description js-toggle-content append-bottom-8"
          v-html="commit.descriptionHtml"
        ></pre>
      </div>
      <div class="commit-actions flex-row d-none d-sm-flex">
        <div
          v-if="commit.signatureHtml"
          v-html="commit.signatureHtml"
        ></div>
        <commit-pipeline-status
          v-if="commit.pipelineStatusPath"
          :endpoint="commit.pipelineStatusPath"
        />
        <div class="commit-sha-group">
          <div
            class="label label-monospace"
            v-text="commit.shortId"
          ></div>
          <clipboard-button
            :text="commit.id"
            :title="__('Copy commit SHA to clipboard')"
            class="btn btn-default"
          />
        </div>
      </div>
    </div>
  </li>
</template>
