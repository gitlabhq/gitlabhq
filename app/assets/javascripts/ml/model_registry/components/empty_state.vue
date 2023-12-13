<script>
import { GlEmptyState } from '@gitlab/ui';
import emptySvgUrl from '@gitlab/svgs/dist/illustrations/empty-state/empty-dag-md.svg?url';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import { MODEL_ENTITIES } from '../constants';

const emptyStateTranslations = {
  [MODEL_ENTITIES.model]: {
    title: s__('MlModelRegistry|Start tracking your machine learning models'),
    description: s__('MlModelRegistry|Store and manage your machine learning models and versions'),
    createNew: s__('MlModelRegistry|Add a model'),
  },
  [MODEL_ENTITIES.modelVersion]: {
    title: s__('MlModelRegistry|Manage versions of your machine learning model'),
    description: s__('MlModelRegistry|Use versions to track performance, parameters, and metadata'),
    createNew: s__('MlModelRegistry|Create a model version'),
  },
};

export default {
  components: {
    GlEmptyState,
  },
  props: {
    entityType: {
      type: String,
      required: true,
      validator(value) {
        return MODEL_ENTITIES[value] !== undefined;
      },
    },
  },
  computed: {
    emptyStateValues() {
      return {
        ...emptyStateTranslations[this.entityType],
        helpPath: helpPagePath('user/project/ml/model_registry/index', {
          anchor: 'creating-machine-learning-models-and-model-versions',
        }),
        emptySvgPath: emptySvgUrl,
      };
    },
  },
};
</script>

<template>
  <gl-empty-state
    :title="emptyStateValues.title"
    :primary-button-text="emptyStateValues.createNew"
    :primary-button-link="emptyStateValues.helpPath"
    :svg-path="emptyStateValues.emptySvgPath"
    :svg-height="null"
    :description="emptyStateValues.description"
    class="gl-py-8"
  />
</template>
