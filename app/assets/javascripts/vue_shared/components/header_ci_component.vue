<script>
/* eslint-disable vue/no-v-html */
import { GlTooltipDirective, GlLink, GlButton, GlTooltip } from '@gitlab/ui';
import { glEmojiTag } from '../../emoji';
import { __, sprintf } from '../../locale';
import CiIconBadge from './ci_badge_link.vue';
import TimeagoTooltip from './time_ago_tooltip.vue';
import UserAvatarImage from './user_avatar/user_avatar_image.vue';

/**
 * Renders header component for job and pipeline page based on UI mockups
 *
 * Used in:
 * - job show page
 * - pipeline show page
 */
export default {
  components: {
    CiIconBadge,
    TimeagoTooltip,
    UserAvatarImage,
    GlLink,
    GlButton,
    GlTooltip,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  EMOJI_REF: 'EMOJI_REF',
  props: {
    status: {
      type: Object,
      required: true,
    },
    itemName: {
      type: String,
      required: true,
    },
    itemId: {
      type: Number,
      required: true,
    },
    time: {
      type: String,
      required: true,
    },
    user: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    hasSidebarButton: {
      type: Boolean,
      required: false,
      default: false,
    },
    shouldRenderTriggeredLabel: {
      type: Boolean,
      required: false,
      default: true,
    },
  },

  computed: {
    userAvatarAltText() {
      return sprintf(__(`%{username}'s avatar`), { username: this.user.name });
    },
    userPath() {
      // GraphQL returns `webPath` and Rest `path`
      return this.user?.webPath || this.user?.path;
    },
    avatarUrl() {
      // GraphQL returns `avatarUrl` and Rest `avatar_url`
      return this.user?.avatarUrl || this.user?.avatar_url;
    },
    statusTooltipHTML() {
      // Rest `status_tooltip_html` which is a ready to work
      // html for the emoji and the status text inside a tooltip.
      // GraphQL returns `status.emoji` and `status.message` which
      // needs to be combined to make the html we want.
      const { emoji } = this.user?.status || {};
      const emojiHtml = emoji ? glEmojiTag(emoji) : '';

      return emojiHtml || this.user?.status_tooltip_html;
    },
    message() {
      return this.user?.status?.message;
    },
  },

  methods: {
    onClickSidebarButton() {
      this.$emit('clickedSidebarButton');
    },
  },
};
</script>

<template>
  <header
    class="page-content-header gl-display-flex gl-min-h-7"
    data-qa-selector="pipeline_header"
    data-testid="ci-header-content"
  >
    <section class="header-main-content gl-mr-3">
      <ci-icon-badge :status="status" />

      <strong data-testid="ci-header-item-text"> {{ itemName }} #{{ itemId }} </strong>

      <template v-if="shouldRenderTriggeredLabel">{{ __('triggered') }}</template>
      <template v-else>{{ __('created') }}</template>

      <timeago-tooltip :time="time" />

      {{ __('by') }}

      <template v-if="user">
        <gl-link
          v-gl-tooltip
          :href="userPath"
          :title="user.email"
          class="js-user-link commit-committer-link"
        >
          <user-avatar-image :img-src="avatarUrl" :img-alt="userAvatarAltText" :size="24" />
          {{ user.name }}
        </gl-link>
        <gl-tooltip v-if="message" :target="() => $refs[$options.EMOJI_REF]">
          {{ message }}
        </gl-tooltip>
        <span
          v-if="statusTooltipHTML"
          :ref="$options.EMOJI_REF"
          :data-testid="message"
          v-html="statusTooltipHTML"
        ></span>
      </template>
    </section>

    <section
      v-if="$slots.default"
      data-testid="ci-header-action-buttons"
      class="gl-display-flex gl-mr-3"
    >
      <slot></slot>
    </section>
    <gl-button
      v-if="hasSidebarButton"
      class="gl-md-display-none gl-ml-auto gl-align-self-start js-sidebar-build-toggle"
      icon="chevron-double-lg-left"
      :aria-label="__('Toggle sidebar')"
      @click="onClickSidebarButton"
    />
  </header>
</template>
