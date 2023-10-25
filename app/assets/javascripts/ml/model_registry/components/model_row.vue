<script>
import { GlLink } from '@gitlab/ui';
import { modelVersionCountMessage } from '../translations';

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
  },
  modelVersionCountMessage,
};
</script>

<template>
  <div class="gl-border-b-solid gl-border-b-1 gl-border-b-gray-100 gl-py-3">
    <gl-link :href="model.path" class="gl-text-body gl-font-weight-bold gl-line-height-24">
      {{ model.name }}
    </gl-link>

    <div class="gl-text-secondary">
      {{ $options.modelVersionCountMessage(model.version, model.versionCount) }}
    </div>
  </div>
</template>
