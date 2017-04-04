export default {
  name: 'SingleAssignee',
  props: {
    store: {
      type: Object,
      required: true,
    },
  },
  computed: {
    user() {
      return this.store.users[0];
    },
    userUrl() {
      return `${this.store.rootPath}${this.user.username}`;
    },
    username() {
      return `@${this.user.username}`;
    },
    avatarAlt() {
      return `${this.user.name}'s avatar`;
    },
  },
  template: `
    <div class="hide-collapsed">
      <a class="author_link bold" :href="userUrl">
        <img width="32"
          class="avatar avatar-inline s32"
          :alt="avatarAlt"
          :src="user.avatarUrl" >
        <span class="author">{{user.name}}</span>
        <span class="username">{{username}}</span>
      </a>
    </div>
  `,
};
