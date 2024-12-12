<script>
import { GlCollapsibleListbox, GlFormInput, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { cloneDeep, isEqual } from 'lodash';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import { s__, __ } from '~/locale';
import { mappingFields } from '../constants';
import {
  getMappingData,
  transformForSave,
  setFieldsLabels,
} from '../utils/mapping_transformations';

export const i18n = {
  columns: {
    gitlabKeyTitle: s__('AlertMappingBuilder|GitLab alert key'),
    payloadKeyTitle: s__('AlertMappingBuilder|Payload alert key'),
    fallbackKeyTitle: s__('AlertMappingBuilder|Define fallback'),
  },
  selectMappingKey: s__('AlertMappingBuilder|Select key'),
  makeSelection: s__('AlertMappingBuilder|Make selection'),
  fallbackTooltip: s__(
    'AlertMappingBuilder|Title is a required field for alerts in GitLab. Should the payload field you specified not be available, specifiy which field we should use instead. ',
  ),
  noResults: __('No matching results'),
};

export default {
  i18n,
  mappingFields,
  components: {
    GlCollapsibleListbox,
    GlFormInput,
    HelpIcon,
  },
  directives: {
    GlTooltip,
  },
  props: {
    alertFields: {
      type: Array,
      required: true,
      validator: (fields) => {
        return (
          fields.length &&
          fields.every(({ name, types, label }) => {
            return typeof name === 'string' && Array.isArray(types) && typeof label === 'string';
          })
        );
      },
    },
    parsedPayload: {
      type: Array,
      required: false,
      default: () => [],
    },
    savedMapping: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      gitlabFields: cloneDeep(this.alertFields),
    };
  },
  computed: {
    mappingData() {
      return getMappingData(this.gitlabFields, this.formattedParsedPayload, this.savedMapping);
    },
    hasFallbackColumn() {
      return this.gitlabFields.some(({ numberOfFallbacks }) => Boolean(numberOfFallbacks));
    },
    formattedParsedPayload() {
      return setFieldsLabels(this.parsedPayload);
    },
  },
  methods: {
    setGitlabFields(index, field) {
      const copy = [...this.gitlabFields];
      copy[index] = field;
      this.gitlabFields = copy;
    },
    setMapping(gitlabKey, mappingFieldLabel, valueKey = mappingFields.mapping) {
      const fieldIndex = this.gitlabFields.findIndex((field) => field.name === gitlabKey);
      const mappingField = this.mappingData[fieldIndex].mappingFields.find(
        (field) => field.label === mappingFieldLabel,
      );
      const updatedField = {
        ...this.gitlabFields[fieldIndex],
        ...{ [valueKey]: mappingField.path },
      };

      this.setGitlabFields(fieldIndex, updatedField);
      this.$emit('onMappingUpdate', transformForSave(this.mappingData));
    },
    setSearchTerm(search = '', searchFieldKey, gitlabKey) {
      const fieldIndex = this.gitlabFields.findIndex((field) => field.name === gitlabKey);
      const updatedField = { ...this.gitlabFields[fieldIndex], ...{ [searchFieldKey]: search } };
      this.setGitlabFields(fieldIndex, updatedField);
    },
    filterFields(searchTerm = '', fields) {
      const search = searchTerm.toLowerCase();
      return fields.filter((field) =>
        field.displayLabel.replace('...', '').toLowerCase().includes(search),
      );
    },
    dropdownItems(searchTerm, fields) {
      return this.filterFields(searchTerm, fields).map((field) => {
        return { text: field.displayLabel, value: field.label, tooltip: field.tooltip };
      });
    },
    selectedValue(mapping) {
      return (
        this.formattedParsedPayload.find((item) => isEqual(item.path, mapping))?.displayLabel ||
        this.$options.i18n.makeSelection
      );
    },
    getFieldValue({ label, types }) {
      const type = types.map((t) => capitalizeFirstCharacter(t.toLowerCase())).join(__(' or '));

      return `${label} (${type})`;
    },
  },
};
</script>

<template>
  <div class="gl-mt-5 gl-table gl-w-full">
    <div class="gl-table-row">
      <h5 id="gitlabFieldsHeader" class="gl-table-cell gl-pb-3 gl-pr-3">
        {{ $options.i18n.columns.gitlabKeyTitle }}
      </h5>
      <h5 class="gl-table-cell gl-pb-3 gl-pr-3">&nbsp;</h5>
      <h5 id="parsedFieldsHeader" class="gl-table-cell gl-pb-3 gl-pr-3">
        {{ $options.i18n.columns.payloadKeyTitle }}
      </h5>
      <h5 v-if="hasFallbackColumn" id="fallbackFieldsHeader" class="gl-table-cell gl-pb-3 gl-pr-3">
        {{ $options.i18n.columns.fallbackKeyTitle }}
        <help-icon v-gl-tooltip :title="$options.i18n.fallbackTooltip" />
      </h5>
    </div>

    <div v-for="gitlabField in mappingData" :key="gitlabField.name" class="gl-table-row">
      <div class="gl-table-cell gl-w-3/10 gl-py-3 gl-pr-3 gl-align-middle">
        <gl-form-input
          aria-labelledby="gitlabFieldsHeader"
          disabled
          :value="getFieldValue(gitlabField)"
        />
      </div>

      <div class="gl-table-cell gl-pr-3 gl-align-middle">
        <div class="right-arrow gl-relative gl-w-full gl-bg-gray-400">
          <i
            class="right-arrow-head gl-absolute gl-inline-block gl-border-solid gl-border-gray-400 gl-p-2"
          ></i>
        </div>
      </div>

      <div class="gl-table-cell gl-w-3/10 gl-py-3 gl-pr-3 gl-align-middle">
        <gl-collapsible-listbox
          :items="dropdownItems(gitlabField.searchTerm, gitlabField.mappingFields)"
          :selected="selectedValue(gitlabField.mapping)"
          :toggle-text="selectedValue(gitlabField.mapping)"
          :header-text="$options.i18n.selectMappingKey"
          :no-results-text="$options.i18n.noResults"
          block
          searchable
          :disabled="!gitlabField.mappingFields.length"
          aria-labelledby="parsedFieldsHeader"
          class="gl-w-full"
          @select="setMapping(gitlabField.name, $event)"
          @search="setSearchTerm($event, 'searchTerm', gitlabField.name)"
        >
          <template #list-item="{ item }">
            <div v-gl-tooltip :title="item.tooltip">{{ item.text }}</div>
          </template>
        </gl-collapsible-listbox>
      </div>

      <div class="gl-table-cell gl-w-3/10 gl-py-3">
        <gl-collapsible-listbox
          v-if="Boolean(gitlabField.numberOfFallbacks)"
          :items="dropdownItems(gitlabField.fallbackSearchTerm, gitlabField.mappingFields)"
          :selected="selectedValue(gitlabField.fallback)"
          :toggle-text="selectedValue(gitlabField.fallback)"
          :header-text="$options.i18n.selectMappingKey"
          :no-results-text="$options.i18n.noResults"
          block
          searchable
          :disabled="!gitlabField.mappingFields.length"
          aria-labelledby="fallbackFieldsHeader"
          class="gl-w-full"
          @select="setMapping(gitlabField.name, $event, $options.mappingFields.fallback)"
          @search="setSearchTerm($event, 'fallbackSearchTerm', gitlabField.name)"
        >
          <template #list-item="{ item }">
            <div v-gl-tooltip :title="item.tooltip">{{ item.text }}</div>
          </template>
        </gl-collapsible-listbox>
      </div>
    </div>
  </div>
</template>
