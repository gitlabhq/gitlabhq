// Analogue of link_to_member_avatar in app/helpers/projects_helper.rb

(() => {
  Vue.component('link-to-member-avatar', {
    props: {
      avatarUrl: {
        type: String,
        required: true,
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
        default: false,
      },
      nonUser: {
        type: Boolean,
        default: false,
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
      size: {
        type: Number,
        required: false,
        default: 32,
      }
    },
    data() {
      return {
        noAvatarUrl: '/assets/no_avatar.png',
        defaultAvatarClass: 'avatar avatar-inline',
      };
    },
    computed: {
      avatarSizeClass() {
        return `s{this.avatarSizeClass}`;
      },
      avatarHtmlClass() {
        return `${this.avatarSizeClass} ${this.defaultAvatarClass}`;
      },
      avatarElemId() {
        return this.username ? `${this.username}-avatar-link` : 'non-user-avatar-link';
      },
      preppedAvatarUrl() {
        return this.avatarUrl || this.noAvatarUrl;
      },
      tooltipClass() {
        return this.showTooltip ? 'has-tooltip' : '';
      },
      avatarClass() {
        return `${this.defaultAvatarClass} ${this.avatarSizeClass} ${this.extraAvatarClass}`;
      },
      disabledClass() {
        return this.nonUser ? 'disabled' : '';
      },
      linkClass() {
        return `author_link ${this.tooltipClass} ${this.extraLinkClass} ${this.disabledClass}`
      },
      tooltipContainerAttr() {
        return this.tooltipContainer || `#${this.avatarElemId}`;
      },
    },
    template: `
      <div class='link-to-member-avatar' :id='avatarElemId'>
        <a :href='profileUrl' :class='linkClass' :data-original-title='displayName' :data-container='tooltipContainerAttr'>
          <svg v-if='avatarHtml' v-html='avatarHtml' :class='avatarHtmlClass' :width='size' :height='size' :alt='displayName'></svg>
          <img :class='avatarClass' :src='preppedAvatarUrl' :width='size' :height='size' :alt='displayName'/>
        </a>
      </div>
    `
  });
})();
