<script>
import { GlButton } from '@gitlab/ui';

export default {
  name: 'LoadMoreDeployments',
  components: { GlButton },
  props: {
    totalDeploymentCount: {
      type: Number,
      required: true,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-items-center gl-justify-center gl-gap-2">
    <span>
      {{ sprintf(__('+ %{n} more deployments'), { n: totalDeploymentCount }) }}
    </span>
    <gl-button
      category="tertiary"
      variant="confirm"
      size="sm"
      :loading="loading"
      @click="$emit('load-more')"
    >
      {{ __('Load more') }}
    </gl-button>
  </div>
</template>
