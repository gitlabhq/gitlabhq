export default {
  name: 'CollapsedAvatar',
  props: {
    name: {
      type: String,
      required: true,
    },
    avatarUrl: {
      type: String,
      required: true,
    },
  },
  computed: {
    alt() {
      return `${this.name}'s avatar`;
    },
  },
  template: `
    <button class="btn-link" type="button">
      <img width="24"
        class="avatar avatar-inline s24"
        :alt="alt"
        :src="avatarUrl" >
      <span class="author">{{name}}</span>
    </button>
  `,
};
