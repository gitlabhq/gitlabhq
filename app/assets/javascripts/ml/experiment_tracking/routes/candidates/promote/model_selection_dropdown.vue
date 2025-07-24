<script>
import { debounce } from 'lodash';
import { GlCollapsibleListbox } from '@gitlab/ui';
import { s__ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import searchModelsQuery from '~/ml/experiment_tracking/graphql/queries/search_models.query.graphql';

export default {
  name: 'ModelSelectionDropdown',
  components: {
    GlCollapsibleListbox,
  },
  props: {
    value: {
      type: Object,
      required: false,
      default: null,
    },
    projectPath: {
      type: String,
      required: true,
    },
  },
  apollo: {
    project: {
      query: searchModelsQuery,
      variables() {
        return {
          name: this.term,
          fullPath: this.projectPath,
        };
      },
      result({ data, error }) {
        if (error) return;

        const { nodes: models } = data.project.mlModels;

        this.searchModelsResult = models.map((model) => ({
          text: model.name,
          value: model.id,
          model,
        }));
      },
      error(error) {
        Sentry.captureException(error);
        this.searchModelsResult = [];
      },
    },
  },
  data() {
    return {
      term: '',
      searchModelsResult: [],
      // eslint-disable-next-line vue/no-unused-properties -- project is part of the component's public API.
      project: null,
    };
  },
  computed: {
    isSearchingModels() {
      return this.$apollo.queries.project?.loading;
    },
    modelSelectorToggleText() {
      return this.value?.name || this.$options.i18n.emptyFieldPlaceholder;
    },
  },
  methods: {
    selectModel(value) {
      const { model } = this.searchModelsResult.find(
        (searchResult) => searchResult.value === value,
      );

      this.$emit('input', model);
    },

    searchModel: debounce(function debounceSearch(term) {
      this.term = term;
    }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS),
  },
  i18n: {
    noResultsMessage: s__('MlExperimentTracking|No results'),
    emptyFieldPlaceholder: s__('MlExperimentTracking|Select a model'),
  },
};
</script>

<template>
  <gl-collapsible-listbox
    block
    searchable
    :items="searchModelsResult"
    :searching="isSearchingModels"
    :no-results-text="$options.i18n.noResultsMessage"
    :toggle-text="modelSelectorToggleText"
    @search="searchModel"
    @select="selectModel"
  />
</template>
