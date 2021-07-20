<script>
import { GlFilteredSearchToken, GlLoadingIcon } from '@gitlab/ui';

export default {
  components: {
    GlFilteredSearchToken,
    GlLoadingIcon,
  },
  inheritAttrs: false,
  props: {
    config: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <gl-filtered-search-token :config="config" v-bind="{ ...$attrs }" v-on="$listeners">
    <template #suggestions>
      <div class="m-1">
        <gl-loading-icon v-if="config.loading" size="sm" />
        <div v-else class="py-1 px-2 text-muted">
          {{ config.noOptionsText }}
        </div>
      </div>
    </template>
  </gl-filtered-search-token>
</template>
