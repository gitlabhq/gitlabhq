// Analogue of link_to_member_avatar in app/helpers/projects_helper.rb
import pendingAvatarSvg from 'ee_icons/_icon_dotted_circle.svg';

export default {
  props: {
    avatarUrl: {
      type: String,
      required: false,
    },
    profileUrl: {
      type: String,
      required: false,
      default: '',
    },
    displayName: {
      type: String,
      required: false,
    },
    extraAvatarClass: {
      type: String,
      default: '',
      required: false,
    },
    extraLinkClass: {
      type: String,
      default: '',
      required: false,
    },
    showTooltip: {
      type: Boolean,
      required: false,
      default: true,
    },
    clickable: {
      type: Boolean,
      default: true,
      required: false,
    },
    tooltipContainer: {
      type: String,
      required: false,
    },
    avatarHtml: {
      type: String,
      required: false,
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
      return `author_link ${this.tooltipClass} ${this.extraLinkClass} ${this.disabledClass}`;
    },
    tooltipContainerAttr() {
      return this.tooltipContainer || 'body';
    },
  },
  template: `
    <div class="link-to-member-avatar">
      <a
        :href="profileUrl"
        :class="linkClass"
        :title="displayName"
        :data-container="tooltipContainerAttr">
        <img
          v-if="avatarUrl"
          :class="avatarClass"
          :src="avatarUrl"
          :width="avatarSize"
          :height="avatarSize"
          :alt="displayName"/>
        <span
          v-else
          v-html="pendingAvatarSvg"
          :class="avatarHtmlClass"
          :width="avatarSize"
          :height="avatarSize">
        </span>
      </a>
    </div>
  `,
};
