import MRWidgetAuthor from './mr_widget_author';

export default {
  name: 'MRWidgetAuthorTime',
  props: {
    actionText: { type: String, required: true },
    author: { type: Object, required: true },
    dateTitle: { type: String, required: true },
    dateReadable: { type: String, required: true },
  },
  components: {
    'mr-widget-author': MRWidgetAuthor,
  },
  template: `
    <h4 class="js-mr-widget-author">
      {{actionText}}
      <mr-widget-author :author="author" />
      <time
        :title="dateTitle"
        data-toggle="tooltip"
        data-placement="top"
        data-container="body">
        {{dateReadable}}
      </time>
    </h4>
  `,
};
