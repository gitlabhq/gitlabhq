<script>
import { GlTooltipDirective, GlButton, GlAvatarLink, GlAvatarLabeled, GlTooltip } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { isGid, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { glEmojiTag } from '~/emoji';
import { __, sprintf } from '~/locale';
import CiBadgeLink from './ci_badge_link.vue';
import TimeagoTooltip from './time_ago_tooltip.vue';

/**
 * Renders header component for job and pipeline page based on UI mockups
 *
 * Used in:
 * - job show page
 * - pipeline show page
 */
export default {
  components: {
    CiBadgeLink,
    TimeagoTooltip,
    GlButton,
    GlAvatarLink,
    GlAvatarLabeled,
    GlTooltip,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
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
      type: String,
      required: false,
      default: '',
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
    webUrl() {
      // GraphQL returns `webUrl` and Rest `web_url`
      return this.user?.webUrl || this.user?.web_url;
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
    item() {
      if (this.itemId) {
        return `${this.itemName} #${this.itemId}`;
      }

      return this.itemName;
    },
    userId() {
      return isGid(this.user?.id) ? getIdFromGraphQLId(this.user?.id) : this.user?.id;
    },
  },

  methods: {
    onClickSidebarButton() {
      this.$emit('clickedSidebarButton');
    },
  },
  safeHtmlConfig: { ADD_TAGS: ['gl-emoji'] },
};
</script>

<template>
  <header
    class="page-content-header gl-md-display-flex gl-min-h-7"
    data-qa-selector="pipeline_header"
    data-testid="ci-header-content"
  >
    <section class="header-main-content gl-mr-3">
      <ci-badge-link class="gl-mr-3" :status="status" />

      <strong data-testid="ci-header-item-text">{{ item }}</strong>

      <template v-if="shouldRenderTriggeredLabel">{{ __('triggered') }}</template>
      <template v-else>{{ __('created') }}</template>

      <timeago-tooltip :time="time" />

      {{ __('by') }}

      <template v-if="user">
        <gl-avatar-link
          :data-user-id="userId"
          :data-username="user.username"
          :data-name="user.name"
          :href="webUrl"
          target="_blank"
          class="js-user-link gl-vertical-align-middle gl-mx-2 gl-align-items-center"
        >
          <gl-avatar-labeled
            :size="24"
            :src="avatarUrl"
            :label="user.name"
            class="gl-display-none gl-sm-display-inline-flex gl-mx-1"
          />
          <strong class="author gl-display-inline gl-sm-display-none!">@{{ user.username }}</strong>
          <gl-tooltip v-if="message" :target="() => $refs[$options.EMOJI_REF]">
            {{ message }}
          </gl-tooltip>
          <span
            v-if="statusTooltipHTML"
            :ref="$options.EMOJI_REF"
            v-safe-html:[$options.safeHtmlConfig]="statusTooltipHTML"
            class="gl-ml-2"
            :data-testid="message"
          ></span>
        </gl-avatar-link>
      </template>
    </section>

    <!-- eslint-disable-next-line @gitlab/vue-prefer-dollar-scopedslots -->
    <section v-if="$slots.default" data-testid="ci-header-action-buttons" class="gl-display-flex">
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
