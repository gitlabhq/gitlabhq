export default {
  name: 'MRWidgetAuthor',
  props: {
    author: { type: Object, required: true },
    showAuthorName: { type: Boolean, required: false, default: true },
    showAuthorTooltip: { type: Boolean, required: false, default: false },
  },
  template: `
    <a
      :href="author.webUrl || author.web_url"
      class="author-link"
      :class="{ 'has-tooltip': showAuthorTooltip }"
      :title="author.name">
      <img
        :src="author.avatarUrl || author.avatar_url"
        class="avatar avatar-inline s16" />
      <span
        v-if="showAuthorName"
        class="author">{{author.name}}
      </span>
    </a>
  `,
};
