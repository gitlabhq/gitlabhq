<script>
import {
  GlIcon,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlDisclosureDropdownGroup,
  GlModalDirective,
} from '@gitlab/ui';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { s__ } from '~/locale';
import EmptyState from '../components/model_list_empty_state.vue';
import * as i18n from '../translations';
import { BASE_SORT_FIELDS, MLFLOW_USAGE_MODAL_ID } from '../constants';
import getModelsQuery from '../graphql/queries/get_models.query.graphql';
import { makeLoadModelErrorMessage } from '../translations';
import SearchableTable from '../components/searchable_table.vue';
import MlflowUsageModal from '../components/mlflow_usage_modal.vue';

export default {
  name: 'IndexMlModels',
  components: {
    GlIcon,
    TitleArea,
    EmptyState,
    SearchableTable,
    GlDisclosureDropdownGroup,
    GlDisclosureDropdownItem,
    GlDisclosureDropdown,
    MlflowUsageModal,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  provide() {
    return {
      mlflowTrackingUrl: this.mlflowTrackingUrl,
      projectPath: this.projectPath,
      maxAllowedFileSize: this.maxAllowedFileSize,
      markdownPreviewPath: this.markdownPreviewPath,
      canWriteModelRegistry: this.canWriteModelRegistry,
    };
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    canWriteModelRegistry: {
      type: Boolean,
      required: false,
      default: false,
    },
    mlflowTrackingUrl: {
      type: String,
      required: false,
      default: '',
    },
    maxAllowedFileSize: {
      type: Number,
      required: true,
    },
    createModelPath: {
      type: String,
      required: true,
    },
    markdownPreviewPath: {
      type: String,
      required: true,
    },
  },
  apollo: {
    models: {
      query: getModelsQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data?.project?.mlModels ?? [];
      },
      error(error) {
        this.handleError(error);
      },
      skip() {
        return this.skipQueries;
      },
    },
  },
  data() {
    return {
      models: [],
      errorMessage: '',
      skipQueries: true,
      queryVariables: {},
    };
  },
  computed: {
    pageInfo() {
      return this.models?.pageInfo ?? {};
    },
    items() {
      return this.models?.nodes ?? [];
    },
    count() {
      return this.models?.count ?? 0;
    },
    isLoading() {
      return this.$apollo.queries.models.loading;
    },
    createModelItem() {
      return {
        text: this.$options.i18n.create_new_model,
        href: this.createModelPath,
      };
    },
    mlflowUsageModalItem() {
      return {
        text: this.$options.i18n.import_mlflow,
      };
    },
  },
  methods: {
    fetchPage(variables) {
      this.queryVariables = {
        fullPath: this.projectPath,
        ...variables,
        name: variables.name,
        orderBy: variables.orderBy?.toUpperCase() || 'CREATED_AT',
        sort: variables.sort?.toUpperCase() || 'DESC',
      };

      this.errorMessage = '';
      this.skipQueries = false;

      this.$apollo.queries.models.fetchMore({});
    },
    handleError(error) {
      this.errorMessage = makeLoadModelErrorMessage(error.message);
      Sentry.captureException(error);
    },
  },
  i18n: {
    create_import_title: s__('MlModelRegistry|Create/Import'),
    create_new_model: s__('MlModelRegistry|Create new model'),
    import_mlflow: s__('MlModelRegistry|Import model using MLflow'),
    ...i18n,
  },
  sortableFields: BASE_SORT_FIELDS,
  docHref: helpPagePath('user/project/ml/model_registry/_index.md'),
  emptyState: {
    title: s__('MlModelRegistry|Import your machine learning models'),
    description: s__(
      'MlModelRegistry|Create your machine learning using GitLab directly or using the MLflow client',
    ),
    primaryText: s__('MlModelRegistry|Create model'),
  },
  modalId: MLFLOW_USAGE_MODAL_ID,
};
</script>

<template>
  <div>
    <title-area>
      <template #title>
        <div class="gl-flex gl-grow gl-items-center">
          <span>{{ $options.i18n.TITLE_LABEL }}</span>
        </div>
      </template>
      <template #metadata-models-count>
        <div class="detail-page-header-body gl-flex-wrap gl-gap-x-2" data-testid="metadata-item">
          <gl-icon name="machine-learning" />
          {{ $options.i18n.modelsCountLabel(count) }}
        </div>
      </template>
      <template #right-actions>
        <gl-disclosure-dropdown
          v-if="canWriteModelRegistry"
          :toggle-text="$options.i18n.create_import_title"
          toggle-class="gl-w-full"
          data-testid="create-model-button"
          variant="confirm"
          category="primary"
          placement="bottom-end"
        >
          <gl-disclosure-dropdown-item data-testid="create-model-button" :item="createModelItem" />
          <gl-disclosure-dropdown-group bordered>
            <gl-disclosure-dropdown-item
              v-gl-modal="$options.modalId"
              :item="mlflowUsageModalItem"
            />
          </gl-disclosure-dropdown-group>
          <mlflow-usage-modal />
        </gl-disclosure-dropdown>
      </template>
    </title-area>
    <searchable-table
      show-search
      :page-info="pageInfo"
      :models="items"
      :error-message="errorMessage"
      :is-loading="isLoading"
      :sortable-fields="$options.sortableFields"
      @fetch-page="fetchPage"
    >
      <template #empty-state>
        <empty-state
          :title="$options.emptyState.title"
          :description="$options.emptyState.description"
          :primary-text="$options.emptyState.primaryText"
          :primary-link="createModelPath"
        />
      </template>
    </searchable-table>
  </div>
</template>
