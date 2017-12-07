import eventHub from '../../event_hub';
import statusIcon from '../mr_widget_status_icon';

export default {
  name: 'MRWidgetAutoMergeFailed',
  props: {
    mr: { type: Object, required: true },
  },
  data() {
    return {
      isRefreshing: false,
    };
  },
  components: {
    statusIcon,
  },
  methods: {
    refreshWidget() {
      this.isRefreshing = true;
      eventHub.$emit('MRWidgetUpdateRequested', () => {
        this.isRefreshing = false;
      });
    },
  },
  template: `
    <div class="mr-widget-body media">
      <status-icon status="warning" />
      <div class="media-body space-children">
        <span class="bold">
          <template v-if="mr.mergeError">{{mr.mergeError}}.</template>
          This merge request failed to be merged automatically
        </span>
        <button
          @click="refreshWidget"
          :disabled="isRefreshing"
          type="button"
          class="btn btn-xs btn-default">
          <i
            v-if="isRefreshing"
            class="fa fa-spinner fa-spin"
            aria-hidden="true" />
          Refresh
        </button>
      </div>
    </div>
  `,
};
