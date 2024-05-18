<script>
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import getModelVersionQuery from '~/ml/model_registry/graphql/queries/get_model_version.query.graphql';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { makeLoadVersionsErrorMessage } from '~/ml/model_registry/translations';
import ModelVersionDetail from '../components/model_version_detail.vue';
import LoadOrErrorOrShow from '../components/load_or_error_or_show.vue';

export default {
  name: 'ShowMlModelVersionApp',
  components: {
    LoadOrErrorOrShow,
    ModelVersionDetail,
    TitleArea,
  },
  provide() {
    return {
      projectPath: this.projectPath,
      canWriteModelRegistry: this.canWriteModelRegistry,
      importPath: this.importPath,
    };
  },
  props: {
    modelId: {
      type: Number,
      required: true,
    },
    modelVersionId: {
      type: Number,
      required: true,
    },
    versionName: {
      type: String,
      required: true,
    },
    modelName: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    canWriteModelRegistry: {
      type: Boolean,
      required: true,
    },
    importPath: {
      type: String,
      required: true,
    },
  },
  apollo: {
    modelWithModelVersion: {
      query: getModelVersionQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data?.mlModel;
      },
      error(error) {
        this.handleError(error);
      },
    },
  },
  data() {
    return {
      modelWithModelVersion: {},
      errorMessage: '',
    };
  },
  computed: {
    modelVersion() {
      return this.modelWithModelVersion?.version;
    },
    isLoading() {
      return this.$apollo.queries.modelWithModelVersion.loading;
    },
    title() {
      return `${this.modelName} / ${this.versionName}`;
    },
    queryVariables() {
      return {
        modelId: convertToGraphQLId('Ml::Model', this.modelId),
        modelVersionId: convertToGraphQLId('Ml::ModelVersion', this.modelVersionId),
      };
    },
  },
  methods: {
    handleError(error) {
      this.errorMessage = makeLoadVersionsErrorMessage(error.message);
      Sentry.captureException(error, {
        tags: {
          vue_component: 'show_ml_model_version',
        },
      });
    },
  },
};
</script>

<template>
  <div>
    <title-area :title="title" />
    <load-or-error-or-show :is-loading="isLoading" :error-message="errorMessage">
      <model-version-detail :model-version="modelVersion" allow-artifact-import />
    </load-or-error-or-show>
  </div>
</template>
