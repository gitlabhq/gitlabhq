<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'BridgeEmptyState',
  i18n: {
    title: __('This job triggers a downstream pipeline'),
    linkBtnText: __('View downstream pipeline'),
  },
  components: {
    GlButton,
  },
  inject: {
    emptyStateIllustrationPath: {
      type: String,
      require: true,
    },
  },
  props: {
    downstreamPipelinePath: {
      type: String,
      required: false,
      default: undefined,
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-flex-direction-column gl-align-items-center gl-mt-11">
    <img :src="emptyStateIllustrationPath" />
    <h1 class="gl-font-size-h1">{{ $options.i18n.title }}</h1>
    <gl-button
      v-if="downstreamPipelinePath"
      class="gl-mt-3"
      category="secondary"
      variant="confirm"
      size="medium"
      :href="downstreamPipelinePath"
    >
      {{ $options.i18n.linkBtnText }}
    </gl-button>
  </div>
</template>
