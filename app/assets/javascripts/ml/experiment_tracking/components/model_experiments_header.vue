<script>
import { GlBadge } from '@gitlab/ui';
import { __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  components: {
    GlBadge,
  },
  props: {
    pageTitle: {
      type: String,
      required: true,
    },
  },
  i18n: {
    experimentBadgeLabel: __('Experiment'),
  },
  experimentDocHref: helpPagePath('user/project/ml/experiment_tracking/index.md'),
};
</script>

<template>
  <div class="detail-page-header gl-flex-wrap">
    <div class="detail-page-header-body">
      <div class="page-title gl-flex-grow-1 gl-display-flex gl-align-items-center">
        <h3 class="gl-font-size-h-display gl-my-0">{{ pageTitle }}</h3>
        <gl-badge class="gl-mx-4" variant="info" :href="$options.experimentDocHref">
          {{ $options.i18n.experimentBadgeLabel }}
        </gl-badge>
      </div>
      <slot></slot>
    </div>
  </div>
</template>
