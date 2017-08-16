import statusIcon from '../mr_widget_status_icon';

export default {
  name: 'MRWidgetChecking',
  components: {
    statusIcon,
  },
  template: `
    <div class="mr-widget-body media">
      <status-icon status="loading" showDisabledButton />
      <div class="media-body space-children">
        <span class="bold">
          Checking ability to merge automatically
        </span>
      </div>
    </div>
  `,
};
