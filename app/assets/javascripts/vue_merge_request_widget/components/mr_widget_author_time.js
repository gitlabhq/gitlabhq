module.exports = {
  name: 'MRWidgetAuthorTime',
  props: {
    actionText: { type: String, required: true, default: '' },
    author: { type: Object, required: true, default: () => ({}) },
    dateTitle: { type: String, required: true, default: '' },
    dateReadable: { type: String, required: true, default: '' }
  },
  template: `
    <h4>
      {{actionText}}
      <a class="author_link" :href="author.webUrl">
        <img :src="author.avatarUrl" width="16" class="avatar avatar-inline s16" />
        <span class="author">{{author.name}}</span>
      </a>
      <time :data-original-title='dateTitle' data-toggle="tooltip" data-placement="top" data-container="body">
        {{dateReadable}}
      </time>
    </h4>
  `
}
