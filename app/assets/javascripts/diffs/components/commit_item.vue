<script>
import { GlButtonGroup, GlButton, GlTooltipDirective, GlFormCheckbox } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';

import CommitPipelineStatus from '~/projects/tree/components/commit_pipeline_status.vue';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

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
    ModalCopyButton,
    TimeAgoTooltip,
    CommitPipelineStatus,
    GlButtonGroup,
    GlButton,
    GlFormCheckbox,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
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
      return this.author.web_url || `mailto:${this.commit.author_email}`;
    },
    authorAvatar() {
      return this.author.avatar_url || this.commit.author_gravatar_url;
    },
    commitDescription() {
      // Strip the newline at the beginning
      return this.commit.description_html.replace(/^&#x000A;/, '');
    },
  },
  safeHtmlConfig: {
    ADD_TAGS: ['gl-emoji'],
  },
};
</script>

<template>
  <li :class="{ 'js-toggle-container': collapsible }" class="commit">
    <div class="gl-block gl-flex-row-reverse gl-items-start gl-justify-between sm:gl-flex">
      <div class="commit-actions gl-hidden gl-flex-row gl-items-center gl-justify-end sm:gl-flex">
        <div
          v-if="commit.signature_html"
          v-html="commit.signature_html /* eslint-disable-line vue/no-v-html */"
        ></div>
        <commit-pipeline-status
          v-if="commit.pipeline_status_path"
          :endpoint="commit.pipeline_status_path"
          class="mb-2 gl-inline-flex"
        />
        <gl-button-group class="gl-ml-4" data-testid="commit-sha-group">
          <gl-button label class="gl-font-monospace" data-testid="commit-sha-short-id">{{
            commit.short_id
          }}</gl-button>
          <modal-copy-button
            :text="commit.id"
            :title="__('Copy commit SHA')"
            class="input-group-text"
          />
        </gl-button-group>
      </div>
      <div>
        <div class="float-left align-self-start gl-flex gl-items-center">
          <gl-form-checkbox
            v-if="isSelectable"
            :checked="checked"
            class="gl-mt-3"
            @change="$emit('handleCheckboxChange', !checked)"
          />
          <user-avatar-link
            :link-href="authorUrl"
            :img-src="authorAvatar"
            :img-alt="authorName"
            :img-size="32"
            class="avatar-cell gl-my-2 gl-mr-3 gl-hidden sm:gl-block"
          />
        </div>
        <div
          class="commit-detail flex-list gl-flex gl-min-w-0 gl-grow gl-items-center gl-justify-between"
        >
          <div class="commit-content" data-testid="commit-content">
            <a
              v-safe-html:[$options.safeHtmlConfig]="commit.title_html"
              :href="commit.commit_url"
              class="commit-row-message item-title"
            ></a>

            <span class="commit-row-message !gl-block sm:!gl-hidden"
              >&middot; {{ commit.short_id }}</span
            >

            <gl-button
              v-if="commit.description_html && collapsible"
              v-gl-tooltip
              class="js-toggle-button"
              size="small"
              icon="ellipsis_h"
              :title="__('Toggle commit description')"
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
        v-safe-html:[$options.safeHtmlConfig]="commitDescription"
        :class="{ 'js-toggle-content': collapsible, '!gl-block': !collapsible }"
        class="commit-row-description gl-mb-3 gl-whitespace-pre-wrap gl-text-default"
      ></pre>
    </div>
  </li>
</template>
