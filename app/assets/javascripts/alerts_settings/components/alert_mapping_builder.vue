<script>
import {
  GlIcon,
  GlFormInput,
  GlDropdown,
  GlDropdownItem,
  GlSearchBoxByType,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import { cloneDeep, isEqual } from 'lodash';
import Vue from 'vue';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
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
    setMapping(gitlabKey, mappingKey, valueKey = mappingFields.mapping) {
      const fieldIndex = this.gitlabFields.findIndex((field) => field.name === gitlabKey);
      const updatedField = { ...this.gitlabFields[fieldIndex], ...{ [valueKey]: mappingKey } };
      Vue.set(this.gitlabFields, fieldIndex, updatedField);
      this.$emit('onMappingUpdate', transformForSave(this.mappingData));
    },
    setSearchTerm(search = '', searchFieldKey, gitlabKey) {
      const fieldIndex = this.gitlabFields.findIndex((field) => field.name === gitlabKey);
      const updatedField = { ...this.gitlabFields[fieldIndex], ...{ [searchFieldKey]: search } };
      Vue.set(this.gitlabFields, fieldIndex, updatedField);
    },
    filterFields(searchTerm = '', fields) {
      const search = searchTerm.toLowerCase();
      return fields.filter((field) =>
        field.displayLabel.replace('...', '').toLowerCase().includes(search),
      );
    },
    isSelected(fieldValue, mapping) {
      return isEqual(fieldValue, mapping);
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
    noResults(searchTerm, fields) {
      return !this.filterFields(searchTerm, fields).length;
    },
  },
};
</script>

<template>
  <div class="gl-display-table gl-w-full gl-mt-5">
    <div class="gl-display-table-row">
      <h5 id="gitlabFieldsHeader" class="gl-display-table-cell gl-pb-3 gl-pr-3">
        {{ $options.i18n.columns.gitlabKeyTitle }}
      </h5>
      <h5 class="gl-display-table-cell gl-pb-3 gl-pr-3">&nbsp;</h5>
      <h5 id="parsedFieldsHeader" class="gl-display-table-cell gl-pb-3 gl-pr-3">
        {{ $options.i18n.columns.payloadKeyTitle }}
      </h5>
      <h5
        v-if="hasFallbackColumn"
        id="fallbackFieldsHeader"
        class="gl-display-table-cell gl-pb-3 gl-pr-3"
      >
        {{ $options.i18n.columns.fallbackKeyTitle }}
        <gl-icon
          v-gl-tooltip
          name="question"
          class="gl-text-gray-500"
          :title="$options.i18n.fallbackTooltip"
        />
      </h5>
    </div>

    <div v-for="gitlabField in mappingData" :key="gitlabField.name" class="gl-display-table-row">
      <div class="gl-display-table-cell gl-py-3 gl-pr-3 gl-w-30p gl-vertical-align-middle">
        <gl-form-input
          aria-labelledby="gitlabFieldsHeader"
          disabled
          :value="getFieldValue(gitlabField)"
        />
      </div>

      <div class="gl-display-table-cell gl-pr-3 gl-vertical-align-middle">
        <div class="right-arrow">
          <i class="right-arrow-head"></i>
        </div>
      </div>

      <div class="gl-display-table-cell gl-py-3 gl-pr-3 gl-w-30p gl-vertical-align-middle">
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
            :key="`${mappingField.path}__mapping`"
            v-gl-tooltip
            :is-checked="isSelected(gitlabField.mapping, mappingField.path)"
            is-check-item
            :title="mappingField.tooltip"
            @click="setMapping(gitlabField.name, mappingField.path)"
          >
            {{ mappingField.displayLabel }}
          </gl-dropdown-item>
          <gl-dropdown-item v-if="noResults(gitlabField.searchTerm, gitlabField.mappingFields)">
            {{ $options.i18n.noResults }}
          </gl-dropdown-item>
        </gl-dropdown>
      </div>

      <div class="gl-display-table-cell gl-py-3 gl-w-30p">
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
            :key="`${mappingField.path}__fallback`"
            v-gl-tooltip
            :is-checked="isSelected(gitlabField.fallback, mappingField.path)"
            is-check-item
            :title="mappingField.tooltip"
            @click="
              setMapping(gitlabField.name, mappingField.path, $options.mappingFields.fallback)
            "
          >
            {{ mappingField.displayLabel }}
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
