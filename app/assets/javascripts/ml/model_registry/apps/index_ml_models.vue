<script>
import { GlExperimentBadge, GlButton } from '@gitlab/ui';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import EmptyState from '../components/empty_state.vue';
import * as i18n from '../translations';
import { BASE_SORT_FIELDS, MODEL_ENTITIES } from '../constants';
import ModelRow from '../components/model_row.vue';
import ActionsDropdown from '../components/actions_dropdown.vue';
import getModelsQuery from '../graphql/queries/get_models.query.graphql';
import { makeLoadModelErrorMessage } from '../translations';
import SearchableList from '../components/searchable_list.vue';

export default {
  name: 'IndexMlModels',
  components: {
    ModelRow,
    MetadataItem,
    TitleArea,
    GlExperimentBadge,
    GlButton,
    EmptyState,
    ActionsDropdown,
    SearchableList,
  },
  provide() {
    return {
      mlflowTrackingUrl: this.mlflowTrackingUrl,
    };
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    createModelPath: {
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
      errorMessage: undefined,
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

      this.errorMessage = null;
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
  modelEntity: MODEL_ENTITIES.model,
};
</script>

<template>
  <div>
    <title-area>
      <template #title>
        <div class="gl-flex-grow-1 gl-display-flex gl-align-items-center">
          <span>{{ $options.i18n.TITLE_LABEL }}</span>
          <gl-experiment-badge :help-page-url="$options.docHref" />
        </div>
      </template>
      <template #metadata-models-count>
        <metadata-item icon="machine-learning" :text="$options.i18n.modelsCountLabel(count)" />
      </template>
      <template #right-actions>
        <gl-button
          v-if="canWriteModelRegistry"
          :href="createModelPath"
          data-testid="create-model-button"
          >{{ $options.i18n.CREATE_MODEL_LABEL }}</gl-button
        >

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
        <empty-state :entity-type="$options.modelEntity" />
      </template>

      <template #item="{ item }">
        <model-row :model="item" />
      </template>
    </searchable-list>
  </div>
</template>
