<script>
import { GlTooltipDirective, GlLink, GlButton } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import CiIconBadge from './ci_badge_link.vue';
import TimeagoTooltip from './time_ago_tooltip.vue';
import UserAvatarImage from './user_avatar/user_avatar_image.vue';
import LoadingButton from '~/vue_shared/components/loading_button.vue';

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
    LoadingButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
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
    actions: {
      type: Array,
      required: false,
      default: () => [],
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
  },

  methods: {
    onClickAction(action) {
      this.$emit('actionClicked', action);
    },
    onClickSidebarButton() {
      this.$emit('clickedSidebarButton');
    },
  },
};
</script>

<template>
  <header class="page-content-header ci-header-container">
    <section class="header-main-content">
      <ci-icon-badge :status="status" />

      <strong> {{ itemName }} #{{ itemId }} </strong>

      <template v-if="shouldRenderTriggeredLabel">{{ __('triggered') }}</template>
      <template v-else>{{ __('created') }}</template>

      <timeago-tooltip :time="time" />

      {{ __('by') }}

      <template v-if="user">
        <gl-link
          v-gl-tooltip
          :href="user.path"
          :title="user.email"
          class="js-user-link commit-committer-link"
        >
          <user-avatar-image
            :img-src="user.avatar_url"
            :img-alt="userAvatarAltText"
            :tooltip-text="user.name"
            :img-size="24"
          />

          {{ user.name }}
        </gl-link>
        <span v-if="user.status_tooltip_html" v-html="user.status_tooltip_html"></span>
      </template>
    </section>

    <section v-if="actions.length" class="header-action-buttons">
      <template v-for="(action, i) in actions">
        <loading-button
          :key="i"
          :loading="action.isLoading"
          :disabled="action.isLoading"
          :class="action.cssClass"
          container-class="d-inline"
          :label="action.label"
          @click="onClickAction(action)"
        />
      </template>
    </section>
    <gl-button
      v-if="hasSidebarButton"
      id="toggleSidebar"
      class="d-block d-sm-none
sidebar-toggle-btn js-sidebar-build-toggle js-sidebar-build-toggle-header"
      @click="onClickSidebarButton"
    >
      <i class="fa fa-angle-double-left" aria-hidden="true" aria-labelledby="toggleSidebar"> </i>
    </gl-button>
  </header>
</template>
