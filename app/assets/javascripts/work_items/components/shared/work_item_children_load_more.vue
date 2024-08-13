<script>
import { GlButton, GlLoadingIcon } from '@gitlab/ui';

export default {
  components: {
    GlButton,
    GlLoadingIcon,
  },
  props: {
    fetchNextPageInProgress: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <div class="gl-flex">
    <gl-button
      v-if="!fetchNextPageInProgress"
      category="tertiary"
      variant="confirm"
      @click="$emit('fetch-next-page', $event)"
    >
      {{ s__('WorkItem|Load more') }}</gl-button
    >
    <gl-loading-icon v-else size="md" class="gl-ml-4 gl-py-2" />
  </div>
</template>
