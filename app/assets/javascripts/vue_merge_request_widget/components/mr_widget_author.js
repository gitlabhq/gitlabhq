export default {
  name: 'MRWidgetAuthor',
  props: {
    author: { type: Object, required: true },
  },
  template: `
    <a
      :href="author.webUrl"
      class="author-link">
      <img
        :src="author.avatarUrl"
        class="avatar avatar-inline s16" />
      <span class="author">{{author.name}}</span>
    </a>
  `,
};
