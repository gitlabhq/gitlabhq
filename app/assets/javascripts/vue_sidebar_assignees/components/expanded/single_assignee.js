export default {
  name: 'SingleAssignee',
  props: {
    assignees: { type: Object, required: true },
  },
  computed: {
    user() {
      return this.assignees.users[0];
    },
    avatarAlt() {
      return `${this.user.name}'s avatar`;
    },
  },
  template: `
    <div class="hide-collapsed">
      <a class="author_link bold" :href="'/' + user.username">
        <img width="32"
          class="avatar avatar-inline s32"
          :alt="avatarAlt"
          :src="user.avatarUrl" >
        <span class="author">{{user.name}}</span>
        <span class="username">@{{user.username}}</span>
      </a>
    </div>
  `,
};
