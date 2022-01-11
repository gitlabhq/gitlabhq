<script>
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import statusIcon from '../mr_widget_status_icon.vue';

export default {
  name: 'MRWidgetArchived',
  components: {
    statusIcon,
  },
  mixins: [glFeatureFlagMixin()],
};
</script>
<template>
  <div class="mr-widget-body media">
    <div class="space-children">
      <status-icon status="warning" show-disabled-button />
    </div>
    <div class="media-body">
      <span :class="{ 'gl-ml-0! gl-text-body!': glFeatures.restructuredMrWidget }" class="bold">
        {{ s__('mrWidget|Merge unavailable: merge requests are read-only on archived projects.') }}
      </span>
    </div>
  </div>
</template>
