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
  props: {
    modalId: {
      type: String,
      required: true,
    },
    primaryText: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: true,
    },
  },
  mlflowDocs: s__('MlModelRegistry|Create using MLflow'),
  helpPath: helpPagePath('user/project/ml/model_registry/index', {
    anchor: 'create-machine-learning-models-and-model-versions-by-using-mlflow',
  }),
  emptySvgPath: emptySvgUrl,
  mlflowModalId: MLFLOW_USAGE_MODAL_ID,
};
</script>

<template>
  <gl-empty-state
    :title="title"
    :svg-path="$options.emptySvgPath"
    :svg-height="null"
    class="gl-py-8"
    :description="description"
  >
    <template #actions>
      <gl-button v-gl-modal="modalId" variant="confirm" class="gl-mx-2 gl-mb-3">{{
        primaryText
      }}</gl-button>
      <gl-button v-gl-modal="$options.mlflowModalId" class="gl-mb-3 gl-mr-3 gl-mx-2">
        {{ $options.mlflowDocs }}
      </gl-button>
    </template>
  </gl-empty-state>
</template>
