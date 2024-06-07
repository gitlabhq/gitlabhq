<script>
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { createAlert, VARIANT_DANGER } from '~/alert';
import { s__, sprintf } from '~/locale';
import { setUrlFragment, visitUrlWithAlerts } from '~/lib/utils/url_utility';
import getModelVersionQuery from '~/ml/model_registry/graphql/queries/get_model_version.query.graphql';
import deleteModelVersionMutation from '~/ml/model_registry/graphql/mutations/delete_model_version.mutation.graphql';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { makeLoadVersionsErrorMessage } from '~/ml/model_registry/translations';
import ModelVersionDetail from '../components/model_version_detail.vue';
import LoadOrErrorOrShow from '../components/load_or_error_or_show.vue';
import ModelVersionActionsDropdown from '../components/model_version_actions_dropdown.vue';

export default {
  name: 'ShowMlModelVersionApp',
  components: {
    LoadOrErrorOrShow,
    ModelVersionDetail,
    ModelVersionActionsDropdown,
    TitleArea,
  },
  provide() {
    return {
      projectPath: this.projectPath,
      canWriteModelRegistry: this.canWriteModelRegistry,
      importPath: this.importPath,
      versionName: this.versionName,
      maxAllowedFileSize: this.maxAllowedFileSize,
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
    modelPath: {
      type: String,
      required: true,
    },
    maxAllowedFileSize: {
      type: Number,
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
    modelVersionsPath() {
      return setUrlFragment(this.modelPath, '#versions');
    },
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
    deletionSuccessfulAlert() {
      return {
        id: 'ml-model-version_deleted-successfully',
        message: sprintf(s__('MlModelRegistry|Model version %{versionName} deleted successfully'), {
          versionName: this.versionName,
        }),
        variant: 'success',
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
    handleDeleteError(error) {
      Sentry.captureException(error, {
        tags: {
          vue_component: 'show_ml_model_version',
        },
      });
      createAlert({
        message: s__(
          'MLOps|Something went wrong while trying to delete the model version. Please try again later.',
        ),
        variant: VARIANT_DANGER,
      });
    },
    async deleteModelVersion() {
      try {
        const TYPENAME_MODEL_VERSION = 'Ml::ModelVersion';
        const { data } = await this.$apollo.mutate({
          mutation: deleteModelVersionMutation,
          variables: {
            id: convertToGraphQLId(TYPENAME_MODEL_VERSION, this.modelVersionId),
          },
        });

        if (data.mlModelVersionDelete?.errors?.length > 0) {
          throw data.mlModelVersionDelete.errors.join(', ');
        }

        visitUrlWithAlerts(this.modelVersionsPath, [this.deletionSuccessfulAlert]);
      } catch (error) {
        this.handleDeleteError(error);
      }
    },
  },
};
</script>

<template>
  <div>
    <div
      class="gl-display-flex gl-flex-wrap gl-sm-flex-nowrap gl-justify-content-space-between gl-py-3"
    >
      <div class="gl-flex-direction-column gl-flex-grow-1 gl-min-w-0">
        <title-area :title="title" />
      </div>
      <div class="gl-display-flex gl-align-items-flex-start gl-gap-3 gl-mt-3">
        <model-version-actions-dropdown @delete-model-version="deleteModelVersion" />
      </div>
    </div>

    <load-or-error-or-show :is-loading="isLoading" :error-message="errorMessage">
      <model-version-detail :model-version="modelVersion" allow-artifact-import />
    </load-or-error-or-show>
  </div>
</template>
