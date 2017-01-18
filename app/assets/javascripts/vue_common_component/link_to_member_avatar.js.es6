/* global Vue */
// Analogue of link_to_member_avatar in app/helpers/projects_helper.rb

(() => {
  Vue.component('link-to-member-avatar', {
    props: {
      avatarUrl: {
        type: String,
        required: false,
        default: '/assets/no_avatar.png',
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
      };
    },
    computed: {
      avatarSizeClass() {
        return `s${this.avatarSize}`;
      },
      avatarHtmlClass() {
        return `${this.avatarSizeClass} ${this.avatarBaseClass}`;
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
      <div class='link-to-member-avatar'>
        <a :href='profileUrl' :class='linkClass' :data-original-title='displayName' :data-container='tooltipContainerAttr'>
          <svg v-if='avatarHtml' v-html='avatarHtml' :class='avatarHtmlClass' :width='avatarSize' :height='avatarSize' :alt='displayName'></svg>
          <img :class='avatarClass' :src='avatarUrl' :width='avatarSize' :height='avatarSize' :alt='displayName'/>
        </a>
      </div>
    `,
  });
})();
