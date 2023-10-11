<script>
import { GlLink } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import * as translations from '~/ml/model_registry/routes/models/index/translations';
import Pagination from '~/vue_shared/components/incubation/pagination.vue';

export default {
  name: 'MlExperimentsIndexApp',
  components: {
    GlLink,
    Pagination,
  },
  props: {
    models: {
      type: Array,
      required: true,
    },
    pageInfo: {
      type: Object,
      required: true,
    },
  },
  computed: {
    hasModels() {
      return !isEmpty(this.models);
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

    <template v-if="hasModels">
      <div v-for="model in models" :key="model.name">
        <gl-link :href="model.path"> {{ model.name }} / {{ model.version }} </gl-link>
      </div>

      <pagination v-bind="pageInfo" />
    </template>

    <p v-else class="gl-text-secondary">{{ $options.i18n.NO_MODELS_LABEL }}</p>
  </div>
</template>
