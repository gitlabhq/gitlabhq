export default {
  name: 'MRWidgetAuthorTime',
  props: {
    actionText: { type: String, required: true },
    author: { type: Object, required: true },
    dateTitle: { type: String, required: true },
    dateReadable: { type: String, required: true },
  },
  template: `
    <h4>
      {{actionText}}
      <a class="author_link" :href="author.webUrl">
        <img :src="author.avatarUrl" width="16" class="avatar avatar-inline s16" />
        <span class="author">{{author.name}}</span>
      </a>
      <time :title='dateTitle' data-toggle="tooltip" data-placement="top" data-container="body">
        {{dateReadable}}
      </time>
    </h4>
  `,
};
