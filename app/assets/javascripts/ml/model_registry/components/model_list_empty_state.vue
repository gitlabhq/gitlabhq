<script>
import { GlEmptyState, GlButton, GlModalDirective } from '@gitlab/ui';
import emptySvgUrl from '@gitlab/svgs/dist/illustrations/status/status-new-md.svg';
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
    primaryLink: {
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
  helpPath: helpPagePath('user/project/ml/model_registry/_index', {
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
    class="gl-py-8"
    :description="description"
  >
    <template #actions>
      <gl-button :href="primaryLink" variant="confirm" class="gl-mx-2 gl-mb-3">{{
        primaryText
      }}</gl-button>
      <gl-button v-gl-modal="$options.mlflowModalId" class="gl-mx-2 gl-mb-3 gl-mr-3">
        {{ $options.mlflowDocs }}
      </gl-button>
    </template>
  </gl-empty-state>
</template>
