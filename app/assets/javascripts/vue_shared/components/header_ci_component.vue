<script>
import ciIconBadge from './ci_badge_link.vue';
import timeagoTooltip from './time_ago_tooltip.vue';
import tooltipMixin from '../mixins/tooltip';
import userAvatarLink from './user_avatar/user_avatar_link.vue';

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
      required: true,
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
    timeagoTooltip,
    userAvatarLink,
  },

  computed: {
    userAvatarAltText() {
      return `${this.user.name}'s avatar`;
    },
  },

  methods: {
    onClickAction(action) {
      this.$emit('postAction', action);
    },
  },
};
</script>
<template>
  <header class="page-content-header top-area">
    <section class="header-main-content">

      <ci-icon-badge :status="status" />

      <strong>
        {{itemName}} #{{itemId}}
      </strong>

      triggered

      <timeago-tooltip :time="time" />

      by

      <user-avatar-link
        :link-href="user.web_url"
        :img-src="user.avatar_url"
        :img-alt="userAvatarAltText"
        :tooltip-text="user.name"
        :img-size="24"
        />

      <a
        :href="user.web_url"
        :title="user.email"
        class="js-user-link commit-committer-link"
        ref="tooltip">
        {{user.name}}
      </a>
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
          :class="action.cssClass"
          type="button">
          {{action.label}}
        </button>

      </template>
    </section>
  </header>
</template>
