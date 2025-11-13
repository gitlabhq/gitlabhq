<script>
import { GlCollapsibleListbox, GlButton } from '@gitlab/ui';
import { isEqual, debounce } from 'lodash';
import EMPTY_VARIABLES_SVG from '@gitlab/svgs/dist/illustrations/variables-sm.svg';
import { s__ } from '~/locale';
import { createAlert } from '~/alert';
import { reportToSentry } from '~/ci/utils';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import InputsTableSkeletonLoader from './pipeline_inputs_table/inputs_table_skeleton_loader.vue';
import PipelineInputsTable from './pipeline_inputs_table/pipeline_inputs_table.vue';
import getPipelineInputsQuery from './graphql/queries/pipeline_creation_inputs.query.graphql';
import PipelineInputsPreviewDrawer from './pipeline_inputs_preview_drawer.vue';
import { findMatchingRule, processQueryInputs } from './utils';

const ARRAY_TYPE = 'ARRAY';

export default {
  name: 'PipelineInputsForm',
  components: {
    CrudComponent,
    InputsTableSkeletonLoader,
    PipelineInputsTable,
    GlCollapsibleListbox,
    GlButton,
    PipelineInputsPreviewDrawer,
    HelpPageLink,
  },
  inject: ['projectPath'],
  props: {
    emitModifiedOnly: {
      type: Boolean,
      required: false,
      default: false,
    },
    preselectAllInputs: {
      type: Boolean,
      required: false,
      default: false,
    },
    queryRef: {
      type: String,
      required: true,
    },
    emptySelectionText: {
      type: String,
      required: true,
    },
    savedInputs: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  emits: ['update-inputs', 'update-inputs-metadata'],
  data() {
    return {
      sourceInputs: [],
      inputs: [],
      selectedInputNames: [],
      searchTerm: '',
      showPreviewDrawer: false,
      hasDynamicRules: false,
    };
  },
  apollo: {
    sourceInputs: {
      query: getPipelineInputsQuery,
      variables() {
        return {
          fullPath: this.projectPath,
          ref: this.queryRef,
        };
      },
      skip() {
        return !this.projectPath;
      },
      update({ project }) {
        const queryInputs = project?.ciPipelineCreationInputs || [];
        const { processedInputs, hasDynamicRules } = processQueryInputs(
          queryInputs,
          this.savedInputs,
          this.preselectAllInputs,
        );

        this.hasDynamicRules = hasDynamicRules;

        return processedInputs;
      },
      result() {
        this.inputs = structuredClone(this.sourceInputs);

        this.selectedInputNames = this.inputs
          .filter((input) => input.isSelected && !input.hasRules)
          .map((input) => input.name);

        this.$emit('update-inputs-metadata', {
          totalAvailable: this.inputs.length,
          totalModified: this.modifiedInputs.length,
        });
      },
      error(error) {
        this.createErrorAlert(error);
        reportToSentry(this.$options.name, error);
      },
    },
  },
  computed: {
    hasInputs() {
      return Boolean(this.inputs.length);
    },
    hasSelectedInputs() {
      return Boolean(this.selectedInputNames.length);
    },
    inputsToEmit() {
      return this.emitModifiedOnly ? this.modifiedInputs : this.processedInputs;
    },
    isLoading() {
      return this.$apollo.queries.sourceInputs.loading;
    },
    modifiedInputs() {
      return this.processedInputs.filter((input) => !isEqual(input.value, input.default));
    },
    newlyModifiedInputs() {
      return this.processedInputs.filter((input) => {
        if (input.savedValue === undefined) return false;

        return !isEqual(input.value, input.savedValue) && !isEqual(input.value, input.default);
      });
    },
    nameValuePairs() {
      return this.inputsToEmit.flatMap((input) => {
        const baseNameValuePair = {
          name: input.name,
          value: this.formatInputValue(input),
        };

        if (input.isSelected) {
          return [baseNameValuePair];
        }
        if (input.savedValue !== undefined) {
          return [{ ...baseNameValuePair, destroy: true }];
        }
        return [];
      });
    },
    inputsList() {
      return this.inputs
        .filter((input) => !input.hasRules)
        .map((input) => ({ text: input.name, value: input.name }));
    },
    selectedInputsList() {
      return this.selectedInputNames.map((name) => ({ text: name, value: name }));
    },
    availableInputsList() {
      return this.inputsList.filter((input) => !this.selectedInputNames.includes(input.value));
    },
    searchFilteredInputs() {
      return this.inputsList.filter((input) =>
        input.text.toLowerCase().includes(this.searchTerm.toLowerCase()),
      );
    },
    filteredInputsList() {
      if (this.searchTerm) {
        return this.searchFilteredInputs;
      }

      if (!this.hasSelectedInputs) {
        return this.inputsList;
      }

      const items = [
        {
          text: s__('Pipelines|Selected'),
          options: this.selectedInputsList,
        },
      ];

      if (this.availableInputsList.length) {
        items.push({
          textSrOnly: true,
          text: s__('Pipelines|Available'),
          options: this.availableInputsList,
        });
      }

      return items;
    },
    processedInputs() {
      if (!this.hasDynamicRules) return this.inputs;

      return this.inputs.map((input) => {
        if (!input.hasRules) return input;

        const matchingRule = findMatchingRule(input.rules, this.inputs);

        if (matchingRule) {
          const options = matchingRule.options || [];
          const isValueValid = Array.isArray(options) && options.includes(input.value);

          return {
            ...input,
            options,
            value: isValueValid ? input.value : matchingRule.default || '',
            isSelected: true,
          };
        }

        return {
          ...input,
          options: [],
          value: '',
          isSelected: false,
        };
      });
    },
  },
  created() {
    this.debouncedSearch = debounce((searchTerm) => {
      this.searchTerm = searchTerm;
    }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    createErrorAlert(error) {
      const graphQLErrors = error?.graphQLErrors?.map((err) => err.message) || [];
      const message = graphQLErrors.length
        ? graphQLErrors.join(', ')
        : s__('Pipelines|There was a problem fetching the pipeline inputs. Please try again.');

      createAlert({ message });
    },
    formatInputValue(input) {
      let { value } = input;

      // Convert string to array for ARRAY type inputs
      if (input.type === ARRAY_TYPE && typeof value === 'string' && value) {
        try {
          value = JSON.parse(value);
          if (!Array.isArray(value)) value = [value];
        } catch (e) {
          value = value.split(',').map((item) => item.trim());
        }
      }

      return value;
    },
    handleInputsUpdated(updatedInput) {
      this.updateInputs(updatedInput);
      this.emitEvents();
    },
    updateInputs(updatedInput) {
      this.inputs = this.inputs.map((input) =>
        input.name === updatedInput.name ? updatedInput : input,
      );
    },
    emitEvents() {
      this.$emit('update-inputs-metadata', {
        totalModified: this.modifiedInputs.length,
        newlyModified: this.newlyModifiedInputs.length,
      });
      this.$emit('update-inputs', this.nameValuePairs);
    },
    selectInputs(items) {
      const selectionChangedInputs = [];

      this.inputs = this.inputs.map((input) => {
        const wasSelected = input.isSelected;
        const isSelected = items.includes(input.name);
        const newValue = isSelected ? input.value : input.default;

        if (isSelected !== wasSelected) {
          selectionChangedInputs.push(input.name);
        }

        return {
          ...input,
          isSelected,
          value: newValue,
        };
      });

      this.selectedInputNames = items;

      // Emit events for inputs that had selection changes
      if (selectionChangedInputs.length > 0) {
        this.emitEvents();
      }
    },
    selectAll() {
      const allInputs = this.searchFilteredInputs.map((input) => input.value);
      this.selectInputs(allInputs);
    },
    deselectAll() {
      this.inputs = this.inputs.map((input) => ({
        ...input,
        isSelected: false,
        value: input.default,
      }));

      this.selectedInputNames = [];
      this.emitEvents();
    },
    handleSearch(searchTerm) {
      this.debouncedSearch(searchTerm);
    },
  },

  EMPTY_VARIABLES_SVG,
};
</script>

<template>
  <crud-component
    :description="
      __(
        'Specify the input values to use in this pipeline. Any inputs left unselected will use their default values.',
      )
    "
    :title="s__('Pipelines|Inputs')"
  >
    <template v-if="hasInputs" #actions>
      <gl-collapsible-listbox
        v-model="selectedInputNames"
        :items="filteredInputsList"
        :toggle-text="s__('Pipelines|Select inputs')"
        :header-text="s__('Pipelines|Inputs')"
        :search-placeholder="s__('Pipelines|Search input name')"
        :show-select-all-button-label="__('Select all')"
        :reset-button-label="__('Clear')"
        searchable
        multiple
        placement="bottom-end"
        size="small"
        @reset="deselectAll"
        @select="selectInputs"
        @select-all="selectAll"
        @search="handleSearch"
      />

      <gl-button category="secondary" size="small" @click="showPreviewDrawer = true">
        {{ s__('Pipelines|Preview inputs') }}
      </gl-button>

      <pipeline-inputs-preview-drawer
        :open="showPreviewDrawer"
        :inputs="processedInputs"
        @close="showPreviewDrawer = false"
      />
    </template>

    <inputs-table-skeleton-loader v-if="isLoading" />
    <pipeline-inputs-table
      v-else-if="hasSelectedInputs"
      :inputs="processedInputs"
      @update="handleInputsUpdated"
    />
    <template v-if="!hasSelectedInputs && !isLoading" #empty>
      <div
        v-if="hasInputs"
        class="gl-flex gl-flex-col gl-items-center gl-justify-center gl-p-2"
        data-testid="empty-selection-state"
      >
        <img
          :alt="s__('Pipelines|Pipeline inputs empty state image')"
          :src="$options.EMPTY_VARIABLES_SVG"
          class="gl-mb-3"
        />
        {{ emptySelectionText }}
      </div>
      <div v-else class="gl-text-center" data-testid="no-inputs-empty-state">
        {{ s__('Pipelines|There are no inputs for this configuration.') }}

        <help-page-link href="ci/inputs/_index.md">
          {{ s__('Pipelines|How do I use inputs?') }}
        </help-page-link>
      </div>
    </template>
  </crud-component>
</template>
