<script>
  import loadingIcon from '~/vue_shared/components/loading_icon.vue';
  import callout from '~/vue_shared/components/callout.vue';
  import { s__ } from '~/locale';
  import eventHub from '../../event_hub';
  import statusIcon from '../mr_widget_status_icon.vue';
  import { ReadyToMergeState } from '../../dependencies';

  export default {
    name: 'MRWidgetAutoMergeFailed',
    components: {
      statusIcon,
      loadingIcon,
      callout,
      'mr-widget-ready-to-merge': ReadyToMergeState,
    },
    props: {
      mr: {
        type: Object,
        required: true,
      },
      service: {
        type: Object,
        required: false,
        default: () => {},
      },
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
      calloutMessage() {
        return this.mr.mergeError ? `${this.mr.mergeError}.` : s__('mrWidget|This merge request failed to be merged automatically');
      },
    },
  };
</script>
<template>
  <div class="mr-widget-body">
    <mr-widget-ready-to-merge
      :mr="mr"
      :service="service"
    />
    <div class="mr-widget-callout media mt-2">
      <callout
        :message="calloutMessage()"
        category="danger"
      />
    </div>
  </div>
</template>
