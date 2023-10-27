<script>
import { GlLink } from '@gitlab/ui';
import { s__, n__ } from '~/locale';

export default {
  name: 'MlModelRow',
  components: {
    GlLink,
  },
  props: {
    model: {
      type: Object,
      required: true,
    },
  },
  computed: {
    hasVersions() {
      return this.model.version != null;
    },
    modelVersionCountMessage() {
      if (!this.model.versionCount) return s__('MlModelRegistry|No registered versions');

      return n__(
        'MlModelRegistry|· No other versions',
        'MlModelRegistry|· %d versions',
        this.model.versionCount,
      );
    },
  },
};
</script>

<template>
  <div class="gl-border-b-solid gl-border-b-1 gl-border-b-gray-100 gl-py-3">
    <gl-link :href="model.path" class="gl-text-body gl-font-weight-bold gl-line-height-24">
      {{ model.name }}
    </gl-link>

    <div class="gl-text-secondary">
      <gl-link v-if="hasVersions" :href="model.versionPath">{{ model.version }}</gl-link>

      {{ modelVersionCountMessage }}
    </div>
  </div>
</template>
