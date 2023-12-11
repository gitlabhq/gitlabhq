<script>
import { GlTooltipDirective, GlButton, GlAvatarLink, GlAvatarLabeled, GlTooltip } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { isGid, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { glEmojiTag } from '~/emoji';
import { __, sprintf } from '~/locale';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  components: {
    CiIcon,
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
    name: {
      type: String,
      required: true,
    },
    time: {
      type: String,
      required: true,
    },
    user: {
      type: Object,
      required: true,
    },
    shouldRenderTriggeredLabel: {
      type: Boolean,
      required: true,
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
    class="page-content-header gl-md-display-flex gl-flex-wrap gl-min-h-7 gl-pb-2! gl-w-full"
    data-testid="job-header-content"
  >
    <div
      v-if="name"
      class="gl-display-flex gl-justify-content-space-between gl-align-items-center gl-w-full"
    >
      <h1 class="gl-font-size-h-display gl-my-0 gl-display-inline-block" data-testid="job-name">
        {{ name }}
      </h1>

      <div class="gl-display-flex gl-align-self-start gl-mt-n2">
        <div class="gl-flex-grow-1 gl-flex-shrink-0 gl-text-right">
          <gl-button
            :aria-label="__('Toggle sidebar')"
            category="secondary"
            class="gl-lg-display-none gl-ml-2"
            icon="chevron-double-lg-left"
            @click="onClickSidebarButton"
          />
        </div>
      </div>
    </div>
    <section class="header-main-content gl-display-flex gl-align-items-center gl-mr-3">
      <ci-icon class="gl-mr-3" :status="status" show-status-text />

      <template v-if="shouldRenderTriggeredLabel">{{ __('Started') }}</template>
      <template v-else>{{ __('Created') }}</template>

      <timeago-tooltip :time="time" class="gl-mx-2" />

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
  </header>
</template>
