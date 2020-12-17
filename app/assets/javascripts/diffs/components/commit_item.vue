<script>
/* eslint-disable vue/no-v-html */
import { mapActions } from 'vuex';
import { GlButtonGroup, GlButton, GlTooltipDirective, GlIcon } from '@gitlab/ui';

import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

import CommitPipelineStatus from '~/projects/tree/components/commit_pipeline_status_component.vue';

import initUserPopovers from '../../user_popovers';
import { setUrlParams } from '../../lib/utils/url_utility';

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
 * EXCEPTION WARNING
 * 1. The commit navigation buttons (next neighbor, previous neighbor)
 *    are not duplicated because:
 *     - We don't have the same data available on the Rails side (yet,
 *        without backend work)
 *     - This Vue component should always be what's used when in the
 *        context of an MR diff, so the HAML should never have any idea
 *        about navigating among commits.
 */

export default {
  components: {
    UserAvatarLink,
    ClipboardButton,
    TimeAgoTooltip,
    CommitPipelineStatus,
    GlButtonGroup,
    GlButton,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    isSelectable: {
      type: Boolean,
      required: false,
      default: false,
    },
    commit: {
      type: Object,
      required: true,
    },
    checked: {
      type: Boolean,
      required: false,
      default: false,
    },
    collapsible: {
      type: Boolean,
      required: false,
      default: true,
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
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return this.author.web_url || `mailto:${this.commit.author_email}`;
    },
    authorAvatar() {
      return this.author.avatar_url || this.commit.author_gravatar_url;
    },
    commitDescription() {
      // Strip the newline at the beginning
      return this.commit.description_html.replace(/^&#x000A;/, '');
    },
    nextCommitUrl() {
      return this.commit.next_commit_id
        ? setUrlParams({ commit_id: this.commit.next_commit_id })
        : '';
    },
    previousCommitUrl() {
      return this.commit.prev_commit_id
        ? setUrlParams({ commit_id: this.commit.prev_commit_id })
        : '';
    },
    hasNeighborCommits() {
      return this.commit.next_commit_id || this.commit.prev_commit_id;
    },
  },
  created() {
    this.$nextTick(() => {
      initUserPopovers(this.$el.querySelectorAll('.js-user-link'));
    });
  },
  methods: {
    ...mapActions('diffs', ['moveToNeighboringCommit']),
  },
};
</script>

<template>
  <li :class="{ 'js-toggle-container': collapsible }" class="commit">
    <div
      class="d-block d-sm-flex flex-row-reverse justify-content-between align-items-start flex-lg-row-reverse"
    >
      <div
        class="commit-actions flex-row d-none d-sm-flex align-items-start flex-wrap justify-content-end"
      >
        <div v-if="commit.signature_html" v-html="commit.signature_html"></div>
        <commit-pipeline-status
          v-if="commit.pipeline_status_path"
          :endpoint="commit.pipeline_status_path"
          class="d-inline-flex mb-2"
        />
        <gl-button-group class="gl-ml-4 gl-mb-4" data-testid="commit-sha-group">
          <gl-button
            label
            class="gl-font-monospace"
            data-testid="commit-sha-short-id"
            v-text="commit.short_id"
          />
          <clipboard-button
            :text="commit.id"
            :title="__('Copy commit SHA')"
            class="input-group-text"
          />
        </gl-button-group>
        <div
          v-if="hasNeighborCommits && glFeatures.mrCommitNeighborNav"
          class="commit-nav-buttons ml-3"
        >
          <gl-button-group>
            <gl-button
              :href="previousCommitUrl"
              :disabled="!commit.prev_commit_id"
              @click.prevent="moveToNeighboringCommit({ direction: 'previous' })"
            >
              <span
                v-if="!commit.prev_commit_id"
                v-gl-tooltip
                class="h-100 w-100 position-absolute"
                :title="__('You\'re at the first commit')"
              ></span>
              <gl-icon name="chevron-left" />
              {{ __('Prev') }}
            </gl-button>
            <gl-button
              :href="nextCommitUrl"
              :disabled="!commit.next_commit_id"
              @click.prevent="moveToNeighboringCommit({ direction: 'next' })"
            >
              <span
                v-if="!commit.next_commit_id"
                v-gl-tooltip
                class="h-100 w-100 position-absolute"
                :title="__('You\'re at the last commit')"
              ></span>
              {{ __('Next') }}
              <gl-icon name="chevron-right" />
            </gl-button>
          </gl-button-group>
        </div>
      </div>
      <div>
        <div class="d-flex float-left align-items-center align-self-start">
          <input
            v-if="isSelectable"
            class="mr-2"
            type="checkbox"
            :checked="checked"
            @change="$emit('handleCheckboxChange', $event.target.checked)"
          />
          <user-avatar-link
            :link-href="authorUrl"
            :img-src="authorAvatar"
            :img-alt="authorName"
            :img-size="40"
            class="avatar-cell d-none d-sm-block"
          />
        </div>
        <div class="commit-detail flex-list">
          <div class="commit-content qa-commit-content">
            <a
              :href="commit.commit_url"
              class="commit-row-message item-title"
              v-html="commit.title_html"
            ></a>

            <span class="commit-row-message d-block d-sm-none">&middot; {{ commit.short_id }}</span>

            <gl-button
              v-if="commit.description_html && collapsible"
              class="js-toggle-button"
              size="small"
              icon="ellipsis_h"
              :aria-label="__('Toggle commit description')"
            />

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
          </div>
        </div>
      </div>
    </div>
    <div>
      <pre
        v-if="commit.description_html"
        :class="{ 'js-toggle-content': collapsible, 'd-block': !collapsible }"
        class="commit-row-description gl-mb-3 text-dark"
        v-html="commitDescription"
      ></pre>
    </div>
  </li>
</template>
