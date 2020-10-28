<script>
import { GlEmptyState, GlButton } from '@gitlab/ui';
import { DEVOPS_ADOPTION_STRINGS } from '../constants';

export default {
  name: 'DevopsAdoptionEmptyState',
  inject: ['emptyStateSvgPath'],
  components: {
    GlEmptyState,
    GlButton,
  },
  i18n: DEVOPS_ADOPTION_STRINGS.emptyState,
};
</script>
<template>
  <gl-empty-state
    :title="$options.i18n.title"
    :description="$options.i18n.description"
    :svg-path="emptyStateSvgPath"
  >
    <template #actions>
      <gl-button variant="info">{{ $options.i18n.button }}</gl-button>
    </template>
  </gl-empty-state>
</template>
