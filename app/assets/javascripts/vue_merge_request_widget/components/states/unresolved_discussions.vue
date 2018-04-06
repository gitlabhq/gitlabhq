<script>
import statusIcon from '../mr_widget_status_icon.vue';

export default {
  name: 'UnresolvedDiscussions',
  components: {
    statusIcon,
  },
  props: {
    mr: { type: Object, required: true },
  },
};
</script>

<template>
  <div class="mr-widget-body media">
    <status-icon
      status="warning"
      :show-disabled-button="true"
    />
    <div class="media-body space-children">
      <span class="bold">
        There are unresolved discussions. Please resolve these discussions
      </span>
      <a
        v-if="mr.createIssueToResolveDiscussionsPath"
        :href="mr.createIssueToResolveDiscussionsPath"
        class="btn btn-default btn-xs js-create-issue">
        Create an issue to resolve them later
      </a>
    </div>
  </div>
</template>
