import tooltip from '../../vue_shared/directives/tooltip';

export default {
  name: 'MRWidgetAuthor',
  props: {
    author: { type: Object, required: true },
    showAuthorName: { type: Boolean, required: false, default: true },
    showAuthorTooltip: { type: Boolean, required: false, default: false },
  },
  directives: {
    tooltip,
  },
  template: `
    <a
      :href="author.webUrl || author.web_url"
      class="author-link inline"
      :v-tooltip="showAuthorTooltip"
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
