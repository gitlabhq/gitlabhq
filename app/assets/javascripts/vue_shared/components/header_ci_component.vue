<script>
import CiIconBadge from './ci_badge_link.vue';
import LoadingIcon from './loading_icon.vue';
import TimeagoTooltip from './time_ago_tooltip.vue';
import tooltip from '../directives/tooltip';
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
    LoadingIcon,
    TimeagoTooltip,
    UserAvatarImage,
  },
  directives: {
    tooltip,
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
      return `${this.user.name}'s avatar`;
    },
  },

  methods: {
    onClickAction(action) {
      this.$emit('actionClicked', action);
    },
  },
};
</script>

<template>
  <header class="page-content-header ci-header-container">
    <section class="header-main-content">

      <ci-icon-badge :status="status" />

      <strong>
        {{ itemName }} #{{ itemId }}
      </strong>

      <template v-if="shouldRenderTriggeredLabel">
        triggered
      </template>
      <template v-else>
        created
      </template>

      <timeago-tooltip :time="time" />

      by

      <template v-if="user">
        <a
          v-tooltip
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
        </a>
      </template>
    </section>

    <section
      class="header-action-buttons"
      v-if="actions.length"
    >
      <template
        v-for="(action, i) in actions"
      >
        <a
          v-if="action.type === 'link'"
          :href="action.path"
          :class="action.cssClass"
          :key="i"
        >
          {{ action.label }}
        </a>

        <a
          v-else-if="action.type === 'ujs-link'"
          :href="action.path"
          data-method="post"
          rel="nofollow"
          :class="action.cssClass"
          :key="i"
        >
          {{ action.label }}
        </a>

        <button
          v-else-if="action.type === 'button'"
          @click="onClickAction(action)"
          :disabled="action.isLoading"
          :class="action.cssClass"
          type="button"
          :key="i"
        >
          {{ action.label }}
          <i
            v-show="action.isLoading"
            class="fa fa-spin fa-spinner"
            aria-hidden="true"
          >
          </i>
        </button>
      </template>
      <button
        v-if="hasSidebarButton"
        type="button"
        class="btn btn-secondary d-block d-sm-none d-md-none
sidebar-toggle-btn js-sidebar-build-toggle js-sidebar-build-toggle-header"
        aria-label="Toggle Sidebar"
        id="toggleSidebar"
      >
        <i
          class="fa fa-angle-double-left"
          aria-hidden="true"
          aria-labelledby="toggleSidebar"
        >
        </i>
      </button>
    </section>
  </header>
</template>
