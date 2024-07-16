<script>
import { GlExperimentBadge } from '@gitlab/ui';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { s__ } from '~/locale';
import EmptyState from '../components/model_list_empty_state.vue';
import * as i18n from '../translations';
import { BASE_SORT_FIELDS, MODEL_CREATION_MODAL_ID } from '../constants';
import ModelRow from '../components/model_row.vue';
import ModelCreate from '../components/model_create.vue';
import ActionsDropdown from '../components/actions_dropdown.vue';
import getModelsQuery from '../graphql/queries/get_models.query.graphql';
import { makeLoadModelErrorMessage } from '../translations';
import SearchableList from '../components/searchable_list.vue';

export default {
  name: 'IndexMlModels',
  components: {
    ModelRow,
    ModelCreate,
    MetadataItem,
    TitleArea,
    GlExperimentBadge,
    EmptyState,
    ActionsDropdown,
    SearchableList,
  },
  provide() {
    return {
      mlflowTrackingUrl: this.mlflowTrackingUrl,
      projectPath: this.projectPath,
      maxAllowedFileSize: this.maxAllowedFileSize,
      markdownPreviewPath: this.markdownPreviewPath,
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
  i18n,
  sortableFields: BASE_SORT_FIELDS,
  docHref: helpPagePath('user/project/ml/model_registry/index.md'),
  emptyState: {
    title: s__('MlModelRegistry|Import your machine learning models'),
    description: s__(
      'MlModelRegistry|Create your machine learning using GitLab directly or using the MLflow client',
    ),
    primaryText: s__('MlModelRegistry|Create model'),
    modalId: MODEL_CREATION_MODAL_ID,
  },
};
</script>

<template>
  <div>
    <title-area>
      <template #title>
        <div class="gl-flex-grow-1 gl-display-flex gl-align-items-center">
          <span>{{ $options.i18n.TITLE_LABEL }}</span>
          <gl-experiment-badge :help-page-url="$options.docHref" type="beta" />
        </div>
      </template>
      <template #metadata-models-count>
        <metadata-item icon="machine-learning" :text="$options.i18n.modelsCountLabel(count)" />
      </template>
      <template #right-actions>
        <model-create v-if="canWriteModelRegistry" />

        <actions-dropdown />
      </template>
    </title-area>
    <searchable-list
      show-search
      :page-info="pageInfo"
      :items="items"
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
          :modal-id="$options.emptyState.modalId"
        />
      </template>

      <template #item="{ item }">
        <model-row :model="item" />
      </template>
    </searchable-list>
  </div>
</template>
