<script>
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import MrWidgetAuthorTime from '../mr_widget_author_time.vue';
import statusIcon from '../mr_widget_status_icon.vue';

export default {
  name: 'MRWidgetClosed',
  components: {
    MrWidgetAuthorTime,
    statusIcon,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    /* TODO: This is providing all store and service down when it
      only needs metrics and targetBranch */
    mr: {
      type: Object,
      required: true,
    },
  },
};
</script>
<template>
  <div class="mr-widget-body media">
    <status-icon status="warning" />
    <div class="media-body">
      <mr-widget-author-time
        :action-text="s__('mrWidget|Closed by')"
        :author="mr.metrics.closedBy"
        :date-title="mr.metrics.closedAt"
        :date-readable="mr.metrics.readableClosedAt"
      />

      <section v-if="!glFeatures.restructuredMrWidget" class="mr-info-list">
        <p>
          {{ s__('mrWidget|The changes were not merged into') }}
          <a :href="mr.targetBranchPath" class="label-branch"> {{ mr.targetBranch }} </a>
        </p>
      </section>
    </div>
  </div>
</template>
