<script>
import { GlEmptyState } from '@gitlab/ui';
import emptySvgUrl from '@gitlab/svgs/dist/illustrations/status/status-new-md.svg';
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

const helpLinks = {
  [MODEL_ENTITIES.model]: helpPagePath('user/project/ml/model_registry/index', {
    anchor: 'create-machine-learning-models-by-using-the-ui',
  }),
  [MODEL_ENTITIES.modelVersion]: helpPagePath('user/project/ml/model_registry/index', {
    anchor: 'create-a-model-version-by-using-the-ui',
  }),
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
        helpPath: helpLinks[this.entityType],
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
    :description="emptyStateValues.description"
    class="gl-py-8"
  />
</template>
