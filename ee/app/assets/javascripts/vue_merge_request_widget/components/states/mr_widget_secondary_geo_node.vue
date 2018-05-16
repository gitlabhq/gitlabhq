<script>
import statusIcon from '~/vue_merge_request_widget/components/mr_widget_status_icon.vue';

export default {
  components: {
    statusIcon,
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
        data-title="About this feature"
        data-toggle="tooltip"
        data-placement="bottom"
        target="_blank"
        rel="noopener noreferrer nofollow"
        data-container="body"
      >
        <i class="fa fa-question-circle"></i>
      </a>
    </div>
  </div>
</template>
