<script>
import { GlLink } from '@gitlab/ui';
import * as translations from '~/ml/model_registry/routes/models/index/translations';

export default {
  name: 'MlExperimentsIndexApp',
  components: {
    GlLink,
  },
  props: {
    models: {
      type: Array,
      required: true,
    },
  },
  i18n: translations,
};
</script>

<template>
  <div>
    <div class="detail-page-header gl-flex-wrap">
      <div class="detail-page-header-body">
        <div class="page-title gl-flex-grow-1 gl-display-flex gl-align-items-center">
          <h2 class="gl-font-size-h-display gl-my-0">{{ $options.i18n.TITLE_LABEL }}</h2>
        </div>
      </div>
    </div>

    <div v-for="model in models" :key="model.name">
      <gl-link :href="model.path"> {{ model.name }} / {{ model.version }} </gl-link>
    </div>
  </div>
</template>
