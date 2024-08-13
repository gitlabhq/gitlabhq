<script>
import { GlBadge } from '@gitlab/ui';
import { __ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import PageHeading from '~/vue_shared/components/page_heading.vue';

export default {
  components: {
    GlBadge,
    PageHeading,
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
  <page-heading>
    <template #heading>
      <span class="gl-inline-flex gl-items-center gl-gap-3">
        {{ pageTitle }}
        <gl-badge variant="info" :href="$options.experimentDocHref">
          {{ $options.i18n.experimentBadgeLabel }}
        </gl-badge>
        <slot></slot>
      </span>
    </template>
  </page-heading>
</template>
