import statusIcon from '../mr_widget_status_icon.vue';

export default {
  name: 'MRWidgetPipelineBlocked',
  components: {
    statusIcon,
  },
  template: `
    <div class="mr-widget-body media">
      <status-icon status="warning" :show-disabled-button="true" />
      <div class="media-body space-children">
        <span class="bold">
          Pipeline blocked. The pipeline for this merge request requires a manual action to proceed
        </span>
      </div>
    </div>
  `,
};
