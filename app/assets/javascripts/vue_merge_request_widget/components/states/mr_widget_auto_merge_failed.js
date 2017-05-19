import eventHub from '../../event_hub';

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
  methods: {
    refreshWidget() {
      this.isRefreshing = true;
      eventHub.$emit('MRWidgetUpdateRequested', () => {
        this.isRefreshing = false;
      });
    },
  },
  template: `
    <div class="mr-widget-body">
      <button
        class="btn btn-success btn-small"
        disabled="true"
        type="button">
        Merge
      </button>
      <span class="bold danger">
        This merge request failed to be merged automatically.
        <button
          @click="refreshWidget"
          :class="{ disabled: isRefreshing }"
          type="button"
          class="btn btn-xs btn-default">
          <i
            v-if="isRefreshing"
            class="fa fa-spinner fa-spin"
            aria-hidden="true" />
          Refresh
        </button>
      </span>
      <div class="merge-error-text danger bold">
        {{mr.mergeError}}
      </div>
    </div>
  `,
};
