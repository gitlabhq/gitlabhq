<script>
import Vue from 'vue';
import {
  GlIcon,
  GlFormInput,
  GlDropdown,
  GlDropdownItem,
  GlSearchBoxByType,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import { s__, __ } from '~/locale';
// Mocks will be removed when integrating with BE is ready
// data format is defined and will be the same as mocked (maybe with some minor changes)
// feature rollout plan - https://gitlab.com/gitlab-org/gitlab/-/issues/262707#note_442529171
import gitlabFieldsMock from './mocks/gitlabFields.json';

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
  components: {
    GlIcon,
    GlFormInput,
    GlDropdown,
    GlDropdownItem,
    GlSearchBoxByType,
  },
  directives: {
    GlTooltip,
  },
  props: {
    payloadFields: {
      type: Array,
      required: false,
      default: () => [],
    },
    mapping: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      gitlabFields: this.gitlabAlertFields,
    };
  },
  inject: {
    gitlabAlertFields: {
      default: gitlabFieldsMock,
    },
  },
  computed: {
    mappingData() {
      return this.gitlabFields.map(gitlabField => {
        const mappingFields = this.payloadFields.filter(({ type }) =>
          type.some(t => gitlabField.compatibleTypes.includes(t)),
        );

        const foundMapping = this.mapping.find(
          ({ alertFieldName }) => alertFieldName === gitlabField.name,
        );

        const { fallbackAlertPaths, payloadAlertPaths } = foundMapping || {};

        return {
          mapping: payloadAlertPaths,
          fallback: fallbackAlertPaths,
          searchTerm: '',
          fallbackSearchTerm: '',
          mappingFields,
          ...gitlabField,
        };
      });
    },
  },
  methods: {
    setMapping(gitlabKey, mappingKey, valueKey) {
      const fieldIndex = this.gitlabFields.findIndex(field => field.name === gitlabKey);
      const updatedField = { ...this.gitlabFields[fieldIndex], ...{ [valueKey]: mappingKey } };
      Vue.set(this.gitlabFields, fieldIndex, updatedField);
    },
    setSearchTerm(search = '', searchFieldKey, gitlabKey) {
      const fieldIndex = this.gitlabFields.findIndex(field => field.name === gitlabKey);
      const updatedField = { ...this.gitlabFields[fieldIndex], ...{ [searchFieldKey]: search } };
      Vue.set(this.gitlabFields, fieldIndex, updatedField);
    },
    filterFields(searchTerm = '', fields) {
      const search = searchTerm.toLowerCase();

      return fields.filter(field => field.label.toLowerCase().includes(search));
    },
    isSelected(fieldValue, mapping) {
      return fieldValue === mapping;
    },
    selectedValue(name) {
      return (
        this.payloadFields.find(item => item.name === name)?.label ||
        this.$options.i18n.makeSelection
      );
    },
    getFieldValue({ label, type }) {
      return `${label} (${type.join(__(' or '))})`;
    },
    noResults(searchTerm, fields) {
      return !this.filterFields(searchTerm, fields).length;
    },
  },
};
</script>

<template>
  <div class="gl-display-table gl-w-full gl-mt-5">
    <div class="gl-display-table-row">
      <h5 id="gitlabFieldsHeader" class="gl-display-table-cell gl-py-3 gl-pr-3">
        {{ $options.i18n.columns.gitlabKeyTitle }}
      </h5>
      <h5 class="gl-display-table-cell gl-py-3 gl-pr-3">&nbsp;</h5>
      <h5 id="parsedFieldsHeader" class="gl-display-table-cell gl-py-3 gl-pr-3">
        {{ $options.i18n.columns.payloadKeyTitle }}
      </h5>
      <h5 id="fallbackFieldsHeader" class="gl-display-table-cell gl-py-3 gl-pr-3">
        {{ $options.i18n.columns.fallbackKeyTitle }}
        <gl-icon
          v-gl-tooltip
          name="question"
          class="gl-text-gray-500"
          :title="$options.i18n.fallbackTooltip"
        />
      </h5>
    </div>

    <div
      v-for="(gitlabField, index) in mappingData"
      :key="gitlabField.name"
      class="gl-display-table-row"
    >
      <div class="gl-display-table-cell gl-py-3 gl-pr-3 w-30p gl-vertical-align-middle">
        <gl-form-input
          aria-labelledby="gitlabFieldsHeader"
          disabled
          :value="getFieldValue(gitlabField)"
        />
      </div>

      <div class="gl-display-table-cell gl-py-3 gl-pr-3">
        <div class="right-arrow" :class="{ 'gl-vertical-align-middle': index === 0 }">
          <i class="right-arrow-head"></i>
        </div>
      </div>

      <div class="gl-display-table-cell gl-py-3 gl-pr-3 w-30p gl-vertical-align-middle">
        <gl-dropdown
          :disabled="!gitlabField.mappingFields.length"
          aria-labelledby="parsedFieldsHeader"
          :text="selectedValue(gitlabField.mapping)"
          class="gl-w-full"
          :header-text="$options.i18n.selectMappingKey"
        >
          <gl-search-box-by-type @input="setSearchTerm($event, 'searchTerm', gitlabField.name)" />
          <gl-dropdown-item
            v-for="mappingField in filterFields(gitlabField.searchTerm, gitlabField.mappingFields)"
            :key="`${mappingField.name}__mapping`"
            :is-checked="isSelected(gitlabField.mapping, mappingField.name)"
            is-check-item
            @click="setMapping(gitlabField.name, mappingField.name, 'mapping')"
          >
            {{ mappingField.label }}
          </gl-dropdown-item>
          <gl-dropdown-item v-if="noResults(gitlabField.searchTerm, gitlabField.mappingFields)">
            {{ $options.i18n.noResults }}
          </gl-dropdown-item>
        </gl-dropdown>
      </div>

      <div class="gl-display-table-cell gl-py-3 w-30p">
        <gl-dropdown
          v-if="Boolean(gitlabField.numberOfFallbacks)"
          :disabled="!gitlabField.mappingFields.length"
          aria-labelledby="fallbackFieldsHeader"
          :text="selectedValue(gitlabField.fallback)"
          class="gl-w-full"
          :header-text="$options.i18n.selectMappingKey"
        >
          <gl-search-box-by-type
            @input="setSearchTerm($event, 'fallbackSearchTerm', gitlabField.name)"
          />
          <gl-dropdown-item
            v-for="mappingField in filterFields(
              gitlabField.fallbackSearchTerm,
              gitlabField.mappingFields,
            )"
            :key="`${mappingField.name}__fallback`"
            :is-checked="isSelected(gitlabField.fallback, mappingField.name)"
            is-check-item
            @click="setMapping(gitlabField.name, mappingField.name, 'fallback')"
          >
            {{ mappingField.label }}
          </gl-dropdown-item>
          <gl-dropdown-item
            v-if="noResults(gitlabField.fallbackSearchTerm, gitlabField.mappingFields)"
          >
            {{ $options.i18n.noResults }}
          </gl-dropdown-item>
        </gl-dropdown>
      </div>
    </div>
  </div>
</template>
