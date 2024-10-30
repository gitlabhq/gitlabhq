<script>
import { GlButton, GlExperimentBadge, GlIcon } from '@gitlab/ui';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { s__ } from '~/locale';
import EmptyState from '../components/model_list_empty_state.vue';
import * as i18n from '../translations';
import { BASE_SORT_FIELDS } from '../constants';
import ActionsDropdown from '../components/actions_dropdown.vue';
import getModelsQuery from '../graphql/queries/get_models.query.graphql';
import { makeLoadModelErrorMessage } from '../translations';
import SearchableTable from '../components/searchable_table.vue';

export default {
  name: 'IndexMlModels',
  components: {
    GlIcon,
    TitleArea,
    GlButton,
    GlExperimentBadge,
    EmptyState,
    ActionsDropdown,
    SearchableTable,
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
  },
};
</script>

<template>
  <div>
    <title-area>
      <template #title>
        <div class="gl-flex gl-grow gl-items-center">
          <span>{{ $options.i18n.TITLE_LABEL }}</span>
          <gl-experiment-badge :help-page-url="$options.docHref" type="beta" />
        </div>
      </template>
      <template #metadata-models-count>
        <div class="detail-page-header-body gl-flex-wrap gl-gap-x-2" data-testid="metadata-item">
          <gl-icon name="machine-learning" />
          {{ $options.i18n.modelsCountLabel(count) }}
        </div>
      </template>
      <template #right-actions>
        <gl-button
          v-if="canWriteModelRegistry"
          data-testid="create-model-button"
          variant="confirm"
          :href="createModelPath"
          >{{ $options.i18n.CREATE_MODEL_LINK_TITLE }}</gl-button
        >

        <actions-dropdown />
      </template>
    </title-area>
    <searchable-table
      show-search
      :page-info="pageInfo"
      :models="items"
      :error-message="errorMessage"
      :is-loading="isLoading"
      :sortable-fields="$options.sortableFields"
      can-write-model-registry
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
