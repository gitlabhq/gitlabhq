import statusIcon from '../mr_widget_status_icon';

export default {
  name: 'MRWidgetArchived',
  components: {
    statusIcon,
  },
  template: `
    <div class="mr-widget-body media">
      <div class="space-children">
        <status-icon status="warning" />
        <button
          type="button"
          class="btn btn-success btn-sm"
          disabled="true">
          Merge
        </button>
      </div>
      <div class="media-body">
        <span class="bold">
          This project is archived, write access has been disabled
        </span>
      </div>
    </div>
  `,
};
