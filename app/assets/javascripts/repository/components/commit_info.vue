<script>
import { GlTooltipDirective, GlLink, GlButton } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';
import defaultAvatarUrl from 'images/no_avatar.png';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';
import getRefMixin from '../mixins/get_ref';

export default {
  components: {
    UserAvatarLink,
    TimeagoTooltip,
    GlButton,
    GlLink,
    UserAvatarImage,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  mixins: [getRefMixin],
  props: {
    commit: {
      type: Object,
      required: true,
    },
    span: {
      type: Number,
      required: false,
      default: null,
    },
    prevBlameLink: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return { showDescription: false };
  },
  computed: {
    commitDescription() {
      // Strip the newline at the beginning
      return this.commit?.descriptionHtml?.replace(/^&#x000A;/, '');
    },
    avatarLinkAltText() {
      return sprintf(__(`%{username}'s avatar`), { username: this.commit.authorName });
    },
    truncateAuthorName() {
      return typeof this.span === 'number' && this.span < 3;
    },
  },
  methods: {
    toggleShowDescription() {
      this.showDescription = !this.showDescription;
    },
  },
  defaultAvatarUrl,
  safeHtmlConfig: {
    ADD_TAGS: ['gl-emoji'],
  },
  i18n: {
    toggleCommitDescription: __('Toggle commit description'),
    authored: __('authored'),
  },
};
</script>

<template>
  <div class="well-segment commit gl-flex gl-w-full !gl-px-5 !gl-py-4">
    <user-avatar-link
      v-if="commit.author"
      :link-href="commit.author.webPath"
      :img-src="commit.author.avatarUrl"
      :img-alt="avatarLinkAltText"
      :img-size="32"
      class="gl-my-2 gl-mr-3"
    />
    <user-avatar-image
      v-else
      class="gl-my-2 gl-mr-3"
      :img-src="commit.authorGravatar || $options.defaultAvatarUrl"
      :size="32"
    />
    <div class="commit-detail flex-list gl-flex gl-min-w-0 gl-grow">
      <div
        class="commit-content gl-inline-flex gl-w-full gl-flex-wrap gl-items-baseline"
        data-testid="commit-content"
      >
        <div class="gl-inline-flex gl-basis-full gl-items-center gl-gap-x-3">
          <gl-link
            v-safe-html:[$options.safeHtmlConfig]="commit.titleHtml"
            :href="commit.webPath"
            :class="{ 'gl-italic': !commit.message }"
            class="commit-row-message item-title gl-line-clamp-1 gl-whitespace-normal !gl-break-all"
          />
          <gl-button
            v-if="commit.descriptionHtml"
            v-gl-tooltip
            :class="{ open: showDescription }"
            :title="$options.i18n.toggleCommitDescription"
            :aria-label="$options.i18n.toggleCommitDescription"
            :selected="showDescription"
            class="!gl-ml-0"
            icon="ellipsis_h"
            @click="toggleShowDescription"
          />
        </div>
        <div
          class="committer gl-basis-full gl-truncate gl-text-sm"
          :class="{ 'gl-inline-flex': truncateAuthorName }"
          data-testid="committer"
        >
          <gl-link
            v-if="commit.author"
            :href="commit.author.webPath"
            class="commit-author-link js-user-link"
            :class="{ 'gl-inline-block gl-truncate': truncateAuthorName }"
          >
            {{ commit.author.name }}</gl-link
          >
          <template v-else>
            {{ commit.authorName }}
          </template>
          {{ $options.i18n.authored }}
          <timeago-tooltip :time="commit.authoredDate" tooltip-placement="bottom" />
        </div>
        <pre
          v-if="commitDescription"
          v-safe-html:[$options.safeHtmlConfig]="commitDescription"
          :class="{ '!gl-block': showDescription }"
          class="commit-row-description gl-mb-3 gl-whitespace-pre-wrap"
        ></pre>
      </div>
      <div class="gl-grow"></div>
      <slot></slot>
    </div>
    <div
      v-if="prevBlameLink"
      v-safe-html:[$options.safeHtmlConfig]="prevBlameLink"
      data-event-tracking="click_previous_blame_on_blob_page"
    ></div>
  </div>
</template>
