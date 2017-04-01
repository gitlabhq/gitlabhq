export default {
  name: 'CollapsedAvatar',
  props: {
    user: {
      type: Object,
      required: true
    },
  },
  computed: {
    alt() {
      return `${this.user.name}'s avatar`;
    },
  },
  template: `
    <button class="btn-link" type="button">
      <img width="24"
        class="avatar avatar-inline s24"
        :alt="alt"
        :src="user.avatarUrl" >
      <span class="author">{{user.name}}</span>
    </button>
  `,
};
