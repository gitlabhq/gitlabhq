<script>
import statusIcon from '../mr_widget_status_icon.vue';

export default {
  name: 'UnresolvedDiscussions',
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
  <div class="mr-widget-body media">
    <status-icon :show-disabled-button="true" status="warning" />
    <div class="media-body space-children">
      <span class="bold">
        {{ s__('mrWidget|There are unresolved threads. Please resolve these threads') }}
      </span>
      <a
        v-if="mr.createIssueToResolveDiscussionsPath"
        :href="mr.createIssueToResolveDiscussionsPath"
        class="btn btn-default btn-sm js-create-issue"
      >
        {{ s__('mrWidget|Create an issue to resolve them later') }}
      </a>
    </div>
  </div>
</template>
