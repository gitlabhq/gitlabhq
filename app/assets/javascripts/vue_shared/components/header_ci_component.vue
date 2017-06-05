<script>
import ciIconBadge from './ci_badge_link.vue';
import loadingIcon from './loading_icon.vue';
import timeagoTooltip from './time_ago_tooltip.vue';
import tooltipMixin from '../mixins/tooltip';
import userAvatarImage from './user_avatar/user_avatar_image.vue';

/**
 * Renders header component for job and pipeline page based on UI mockups
 *
 * Used in:
 * - job show page
 * - pipeline show page
 */
export default {
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
  },

  mixins: [
    tooltipMixin,
  ],

  components: {
    ciIconBadge,
    loadingIcon,
    timeagoTooltip,
    userAvatarImage,
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
  <header class="page-content-header">
    <section class="header-main-content">

      <ci-icon-badge :status="status" />

      <strong>
        {{itemName}} #{{itemId}}
      </strong>

      triggered

      <timeago-tooltip :time="time" />

      by

      <template v-if="user">
        <a
          :href="user.path"
          :title="user.email"
          class="js-user-link commit-committer-link"
          ref="tooltip">

          <user-avatar-image
            :img-src="user.avatar_url"
            :img-alt="userAvatarAltText"
            :tooltip-text="user.name"
            :img-size="24"
            />

          {{user.name}}
        </a>
      </template>
    </section>

    <section
      class="header-action-button nav-controls"
      v-if="actions.length">
      <template
        v-for="action in actions">
        <a
          v-if="action.type === 'link'"
          :href="action.path"
          :class="action.cssClass">
          {{action.label}}
        </a>

        <button
          v-else="action.type === 'button'"
          @click="onClickAction(action)"
          :disabled="action.isLoading"
          :class="action.cssClass"
          type="button">
          {{action.label}}

          <i
            v-show="action.isLoading"
            class="fa fa-spin fa-spinner"
            aria-hidden="true">
          </i>
        </button>
      </template>
    </section>
  </header>
</template>
