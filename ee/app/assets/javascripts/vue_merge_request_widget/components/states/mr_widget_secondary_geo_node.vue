<script>
import tooltip from '~/vue_shared/directives/tooltip';
import statusIcon from '~/vue_merge_request_widget/components/mr_widget_status_icon.vue';

export default {
  components: {
    statusIcon,
  },
  directives: {
    tooltip,
  },
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
};
</script>
<template>
  <div class="media">
    <status-icon
      status="warning"
      show-disabled-button
    />
    <div class="media-body">
      <span class="bold">
        Merge requests are read-only in a secondary Geo node
      </span>
      <a
        :href="mr.geoSecondaryHelpPath"
        :title="__('About this feature')"
        data-placement="bottom"
        v-tooltip
        target="_blank"
        rel="noopener noreferrer nofollow"
        data-container="body"
      >
        <i class="fa fa-question-circle"></i>
      </a>
    </div>
  </div>
</template>
