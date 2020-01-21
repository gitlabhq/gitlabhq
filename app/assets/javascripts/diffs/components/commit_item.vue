<script>
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import Icon from '~/vue_shared/components/icon.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import CommitPipelineStatus from '~/projects/tree/components/commit_pipeline_status_component.vue';
import initUserPopovers from '../../user_popovers';

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
 * https://gitlab.com/gitlab-org/gitlab-foss/issues/51613
 *
 */
export default {
  components: {
    UserAvatarLink,
    Icon,
    ClipboardButton,
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
    author() {
      return this.commit.author || {};
    },
    authorName() {
      return this.author.name || this.commit.author_name;
    },
    authorClass() {
      return this.author.name ? 'js-user-link' : '';
    },
    authorId() {
      return this.author.id ? this.author.id : '';
    },
    authorUrl() {
      // name: 'mailto:' is a false positive: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26#possible-false-positives
      // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
      return this.author.web_url || `mailto:${this.commit.author_email}`;
    },
    authorAvatar() {
      return this.author.avatar_url || this.commit.author_gravatar_url;
    },
  },
  created() {
    this.$nextTick(() => {
      initUserPopovers(this.$el.querySelectorAll('.js-user-link'));
    });
  },
};
</script>

<template>
  <li class="commit flex-row js-toggle-container">
    <user-avatar-link
      :link-href="authorUrl"
      :img-src="authorAvatar"
      :img-alt="authorName"
      :img-size="40"
      class="avatar-cell d-none d-sm-block"
    />
    <div class="commit-detail flex-list">
      <div class="commit-content qa-commit-content">
        <a
          :href="commit.commit_url"
          class="commit-row-message item-title"
          v-html="commit.title_html"
        ></a>

        <span class="commit-row-message d-block d-sm-none">&middot; {{ commit.short_id }}</span>

        <button
          v-if="commit.description_html"
          class="text-expander js-toggle-button"
          type="button"
          :aria-label="__('Toggle commit description')"
        >
          <icon :size="12" name="ellipsis_h" />
        </button>

        <div class="committer">
          <a
            :href="authorUrl"
            :class="authorClass"
            :data-user-id="authorId"
            v-text="authorName"
          ></a>
          {{ s__('CommitWidget|authored') }}
          <time-ago-tooltip :time="commit.authored_date" />
        </div>

        <pre
          v-if="commit.description_html"
          class="commit-row-description js-toggle-content append-bottom-8"
          v-html="commit.description_html"
        ></pre>
      </div>
      <div class="commit-actions flex-row d-none d-sm-flex">
        <div v-if="commit.signature_html" v-html="commit.signature_html"></div>
        <commit-pipeline-status
          v-if="commit.pipeline_status_path"
          :endpoint="commit.pipeline_status_path"
          class="d-inline-flex"
        />
        <div class="commit-sha-group">
          <div class="label label-monospace monospace" v-text="commit.short_id"></div>
          <clipboard-button
            :text="commit.id"
            :title="__('Copy commit SHA')"
            class="btn btn-default"
          />
        </div>
      </div>
    </div>
  </li>
</template>
