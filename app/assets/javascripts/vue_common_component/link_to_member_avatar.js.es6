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
        required: true
      },
      displayName: {
        type: String,
        required: true,
      },
      avatarClass: {
        type: String,
        default: 'avatar avatar-inline s48',
        required: false,
      },
      linkClass: {
        type: String,
        default: 'author_link has-tooltip',
        required: false,
      },
      size: {
        type: Number,
        default: 48,
        required: false
      }
    },
    data() {
      return {
        noAvatarUrl: '/assets/no_avatar.png'
      };
    },
    computed: {
      userProfileUrl() {
        return `/${this.username}`;
      },
      preppedAvatarUrl() {
        return this.avatarUrl || this.noAvatarUrl;
      }
    },
    template: `
    <a :href='userProfileUrl' :class='linkClass' :data-original-title='displayName' data-container='body'>
      <img :class='avatarClass' :src='preppedAvatarUrl' :width='size' :height='size' :alt='displayName'/>
    </a>
  `
  });
})();