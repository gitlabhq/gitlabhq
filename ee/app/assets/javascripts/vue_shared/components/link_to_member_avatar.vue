<script>
// Analogue of link_to_member_avatar in app/helpers/projects_helper.rb
import pendingAvatarSvg from 'ee_icons/_icon_dotted_circle.svg';

export default {
  props: {
    avatarUrl: {
      type: String,
      required: false,
      default: '',
    },
    profileUrl: {
      type: String,
      required: false,
      default: '',
    },
    displayName: {
      type: String,
      required: false,
      default: '',
    },
    extraAvatarClass: {
      type: String,
      required: false,
      default: '',
    },
    extraLinkClass: {
      type: String,
      required: false,
      default: '',
    },
    showTooltip: {
      type: Boolean,
      required: false,
      default: true,
    },
    clickable: {
      type: Boolean,
      required: false,
      default: true,
    },
    tooltipContainer: {
      type: String,
      required: false,
      default: 'body',
    },
    avatarSize: {
      type: Number,
      required: false,
      default: 32,
    },
  },
  data() {
    return {
      avatarBaseClass: 'avatar avatar-inline',
      pendingAvatarSvg,
    };
  },
  computed: {
    avatarSizeClass() {
      return `s${this.avatarSize}`;
    },
    avatarHtmlClass() {
      return `${this.avatarSizeClass} ${this.avatarBaseClass} avatar-placeholder`;
    },
    tooltipClass() {
      return this.showTooltip ? 'has-tooltip' : '';
    },
    avatarClass() {
      return `${this.avatarBaseClass} ${this.avatarSizeClass} ${this.extraAvatarClass}`;
    },
    disabledClass() {
      return !this.clickable ? 'disabled' : '';
    },
    linkClass() {
      return `author-link ${this.tooltipClass} ${this.extraLinkClass} ${this.disabledClass}`;
    },
  },
};
</script>

<template>
  <div class="link-to-member-avatar">
    <a
      :href="profileUrl"
      :class="linkClass"
      :title="displayName"
      :data-container="tooltipContainer"
    >
      <img
        v-if="avatarUrl"
        :class="avatarClass"
        :src="avatarUrl"
        :width="avatarSize"
        :height="avatarSize"
        :alt="displayName"
      />
      <span
        v-else
        :class="avatarHtmlClass"
        :width="avatarSize"
        :height="avatarSize"
        v-html="pendingAvatarSvg"
      >
      </span>
    </a>
  </div>
</template>
