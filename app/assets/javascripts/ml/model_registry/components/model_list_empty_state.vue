<script>
import { GlEmptyState, GlButton, GlModalDirective } from '@gitlab/ui';
import emptySvgUrl from '@gitlab/svgs/dist/illustrations/empty-state/empty-dag-md.svg?url';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import { MLFLOW_USAGE_MODAL_ID } from '../constants';

export default {
  components: {
    GlEmptyState,
    GlButton,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  inject: ['mlflowTrackingUrl'],
  title: s__('MlModelRegistry|Import your machine learning models'),
  description: s__(
    'MlModelRegistry|Create your machine learning using GitLab directly or using the MLflow client',
  ),
  createNew: s__('MlModelRegistry|Create model'),
  mlflowDocs: s__('MlModelRegistry|Create model with MLflow'),
  helpPath: helpPagePath('user/project/ml/model_registry/index', {
    anchor: 'creating-machine-learning-models-and-model-versions',
  }),
  emptySvgPath: emptySvgUrl,
  methods: {
    emitOpenCreateModel() {
      this.$emit('open-create-model');
    },
  },
  modalId: MLFLOW_USAGE_MODAL_ID,
};
</script>

<template>
  <gl-empty-state
    :title="$options.title"
    :svg-path="$options.emptySvgPath"
    :svg-height="null"
    class="gl-py-8"
    :description="$options.description"
  >
    <template #actions>
      <gl-button variant="confirm" class="gl-mx-2 gl-mb-3" @click="emitOpenCreateModel">{{
        $options.createNew
      }}</gl-button>
      <gl-button v-gl-modal="$options.modalId" class="gl-mb-3 gl-mr-3 gl-mx-2">
        {{ $options.mlflowDocs }}
      </gl-button>
    </template>
  </gl-empty-state>
</template>
