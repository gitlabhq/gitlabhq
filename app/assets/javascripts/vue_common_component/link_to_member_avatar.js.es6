/* Analogue of link_to_member_avatar in app/helpers/projects_helper.rb 
  TODO: Support gravatar link generation, adding name text, username text
  TODO: 1:1 configuration compared to link_to_member_avatar
  TODO: Backport to CE
*/
(() => {
  Vue.component('link-to-member-avatar', {
    props: {
      avatarUrl: {
        type: String,
        required: false
      },
      username: {
        type: String,
        required: false,
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
      size: {
        type: Number,
        default: 48,
        required: false
      },
      nonUser: {
        type: Boolean,
        default: false,
        required: false,
      },
      tooltipContainer: {
        type: String,
        required: false,
      }
    },
    data() {
      return {
        noAvatarUrl: '/assets/no_avatar.png'
      };
    },
    computed: {
      avatarElemId() {
        return `${this.username}-avatar-link`;
      },
      userProfileUrl() {
        return this.nonUser || !this.username ? '' : `/${this.username}`;
      },
      preppedAvatarUrl() {
        return this.avatarUrl || this.noAvatarUrl;
      },
      tooltipClass() {
        return this.showTooltip ? 'has-tooltip' : '';
      },
      avatarClass() {
        return `avatar avatar-inline s${this.size} ${this.extraAvatarClass}`
      },
      disabledClass() {
        return this.nonUser ? 'disabled' : '';
      },
      linkClass() {
        return `author_link ${this.tooltipClass} ${this.extraLinkClass} ${this.disabledClass}`
      },
      tooltipContainerAttr() {
        return this.tooltipContainer || `#${this.avatarElemId}`;
      }
    },
    template: `
      <span :id='avatarElemId'>
        <a :href='userProfileUrl' :class='linkClass' :data-original-title='displayName' :data-container='tooltipContainerAttr'>
          <img :class='avatarClass' :src='preppedAvatarUrl' :width='size' :height='size' :alt='displayName'/>
        </a>
      </span>
    `
  });
})();
