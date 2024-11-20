<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  i18n: {
    privateProjectTooltip: s__(
      'CiCatalog|Private - This component project can only be viewed by project members.',
    ),
  },
  components: {
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
};
</script>
<template>
  <gl-icon v-gl-tooltip name="lock" :title="$options.i18n.privateProjectTooltip" variant="subtle" />
</template>
