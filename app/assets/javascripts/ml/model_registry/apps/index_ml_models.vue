<script>
import { isEmpty } from 'lodash';
import * as translations from '~/ml/model_registry/translations';
import Pagination from '~/vue_shared/components/incubation/pagination.vue';
import { BASE_SORT_FIELDS } from '../constants';
import SearchBar from '../components/search_bar.vue';
import ModelRow from '../components/model_row.vue';

export default {
  name: 'IndexMlModels',
  components: {
    Pagination,
    ModelRow,
    SearchBar,
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
  sortableFields: BASE_SORT_FIELDS,
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
      <search-bar :sortable-fields="$options.sortableFields" />
      <model-row v-for="model in models" :key="model.name" :model="model" />
      <pagination v-bind="pageInfo" />
    </template>

    <p v-else class="gl-text-secondary">{{ $options.i18n.NO_MODELS_LABEL }}</p>
  </div>
</template>
