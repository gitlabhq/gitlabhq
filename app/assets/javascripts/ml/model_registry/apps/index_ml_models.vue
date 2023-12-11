<script>
import { isEmpty } from 'lodash';
import { GlBadge } from '@gitlab/ui';
import Pagination from '~/vue_shared/components/incubation/pagination.vue';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import * as i18n from '../translations';
import { BASE_SORT_FIELDS } from '../constants';
import SearchBar from '../components/search_bar.vue';
import ModelRow from '../components/model_row.vue';

export default {
  name: 'IndexMlModels',
  components: {
    Pagination,
    ModelRow,
    SearchBar,
    MetadataItem,
    TitleArea,
    GlBadge,
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
    modelCount: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  computed: {
    hasModels() {
      return !isEmpty(this.models);
    },
  },
  i18n,
  sortableFields: BASE_SORT_FIELDS,
  docHref: helpPagePath('user/project/ml/model_registry/index.md'),
};
</script>

<template>
  <div>
    <title-area>
      <template #title>
        <div class="gl-flex-grow-1 gl-display-flex gl-align-items-center">
          <span>{{ $options.i18n.TITLE_LABEL }}</span>
          <gl-badge variant="neutral" class="gl-mx-4" size="lg" :href="$options.docHref">
            {{ __('Experiment') }}
          </gl-badge>
        </div>
      </template>
      <template #metadata-models-count>
        <metadata-item icon="machine-learning" :text="$options.i18n.modelsCountLabel(modelCount)" />
      </template>
    </title-area>
    <template v-if="hasModels">
      <search-bar :sortable-fields="$options.sortableFields" />
      <model-row v-for="model in models" :key="model.name" :model="model" />
      <pagination v-bind="pageInfo" />
    </template>

    <p v-else class="gl-text-secondary">{{ $options.i18n.NO_MODELS_LABEL }}</p>
  </div>
</template>
