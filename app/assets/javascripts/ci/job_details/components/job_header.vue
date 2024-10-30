<script>
import { GlTooltipDirective, GlButton, GlAvatarLink, GlAvatarLabeled, GlTooltip } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { isGid, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { glEmojiTag } from '~/emoji';
import { __, sprintf } from '~/locale';
import PageHeading from '~/vue_shared/components/page_heading.vue';
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
    PageHeading,
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
  <page-heading v-if="name" data-testid="job-header-content">
    <template #heading>
      <span data-testid="job-name">{{ name }}</span>
    </template>

    <template #actions>
      <gl-button
        :aria-label="__('Toggle sidebar')"
        category="secondary"
        class="gl-ml-2 lg:gl-hidden"
        icon="chevron-double-lg-left"
        @click="onClickSidebarButton"
      />
    </template>

    <template #description>
      <ci-icon class="gl-mr-1" :status="status" show-status-text />
      <template v-if="shouldRenderTriggeredLabel">{{ __('Started') }}</template>
      <template v-else>{{ __('Created') }}</template>

      <timeago-tooltip :time="time" />

      {{ __('by') }}

      <template v-if="user">
        <gl-avatar-link
          :data-user-id="userId"
          :data-username="user.username"
          :data-name="user.name"
          :href="webUrl"
          target="_blank"
          class="js-user-link gl-mx-2 gl-items-center gl-align-middle"
        >
          <gl-avatar-labeled
            :size="24"
            :src="avatarUrl"
            :label="user.name"
            class="gl-hidden sm:gl-inline-flex"
          />
          <strong class="author gl-inline sm:gl-hidden">@{{ user.username }}</strong>
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
    </template>
  </page-heading>
</template>
