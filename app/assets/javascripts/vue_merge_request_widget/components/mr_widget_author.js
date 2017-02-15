export default {
  name: 'MRWidgetAuthor',
  props: {
    author: { type: Object, required: true },
  },
  template: `
    <a class="author_link" :href="author.webUrl">
      <img :src="author.avatarUrl" class="avatar avatar-inline s16" />
      <span class="author">{{author.name}}</span>
    </a>
  `,
};
