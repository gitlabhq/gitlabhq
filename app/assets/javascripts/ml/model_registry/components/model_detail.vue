<script>
import { GlLink } from '@gitlab/ui';
import ModelVersionDetail from '~/ml/model_registry/components/model_version_detail.vue';
import { s__ } from '~/locale';
import { MODEL_VERSION_CREATION_MODAL_ID } from '../constants';
import EmptyState from './model_list_empty_state.vue';

export default {
  name: 'ModelDetail',
  components: {
    EmptyState,
    ModelVersionDetail,
    GlLink,
  },
  provide() {
    return {
      importPath: '',
    };
  },
  props: {
    model: {
      type: Object,
      required: true,
    },
  },
  computed: {
    versionCount() {
      return this.model.versionCount || 0;
    },
  },
  emptyState: {
    title: s__('MlModelRegistry|Manage versions of your machine learning model'),
    description: s__('MlModelRegistry|Use versions to track performance, parameters, and metadata'),
    primaryText: s__('MlModelRegistry|Create model version'),
    modalId: MODEL_VERSION_CREATION_MODAL_ID,
  },
};
</script>

<template>
  <div v-if="model.latestVersion">
    <h3 class="gl-font-lg">
      {{ s__('MlModelRegistry|Latest version') }}:

      <gl-link :href="model.latestVersion._links.showPath" data-testid="model-version-link">
        {{ model.latestVersion.version }}
      </gl-link>
    </h3>

    <model-version-detail :model-version="model.latestVersion" />
  </div>

  <empty-state
    v-else
    :title="$options.emptyState.title"
    :description="$options.emptyState.description"
    :primary-text="$options.emptyState.primaryText"
    :modal-id="$options.emptyState.modalId"
  />
</template>
