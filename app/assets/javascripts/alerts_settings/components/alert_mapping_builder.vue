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
// data format most likely will differ but UI will not
// feature rollout plan - https://gitlab.com/gitlab-org/gitlab/-/issues/262707#note_442529171
import gitlabFields from './mocks/gitlabFields.json';
import parsedMapping from './mocks/parsedMapping.json';

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
  data() {
    return {
      gitlabFields,
    };
  },
  computed: {
    mappingData() {
      return this.gitlabFields.map(gitlabField => {
        const mappingFields = parsedMapping.filter(field => field.type === gitlabField.type);

        return {
          mapping: null,
          fallback: null,
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
      const fieldIndex = this.gitlabFields.findIndex(field => field.key === gitlabKey);
      const updatedField = { ...this.gitlabFields[fieldIndex], ...{ [valueKey]: mappingKey } };
      Vue.set(this.gitlabFields, fieldIndex, updatedField);
    },
    setSearchTerm(search = '', searchFieldKey, gitlabKey) {
      const fieldIndex = this.gitlabFields.findIndex(field => field.key === gitlabKey);
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
    selectedValue(key) {
      return (
        parsedMapping.find(item => item.key === key)?.label || this.$options.i18n.makeSelection
      );
    },
    getFieldValue({ label, type }) {
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
      <h5 class="gl-display-table-cell gl-py-3 gl-pr-3">
        {{ $options.i18n.columns.gitlabKeyTitle }}
      </h5>
      <h5 class="gl-display-table-cell gl-py-3 gl-pr-3">&nbsp;</h5>
      <h5 class="gl-display-table-cell gl-py-3 gl-pr-3">
        {{ $options.i18n.columns.payloadKeyTitle }}
      </h5>
      <h5 class="gl-display-table-cell gl-py-3 gl-pr-3">
        {{ $options.i18n.columns.fallbackKeyTitle }}
        <gl-icon
          v-gl-tooltip
          name="question"
          class="gl-text-gray-500"
          :title="$options.i18n.fallbackTooltip"
        />
      </h5>
    </div>
    <div v-for="gitlabField in mappingData" :key="gitlabField.key" class="gl-display-table-row">
      <div class="gl-display-table-cell gl-py-3 gl-pr-3 w-30p">
        <gl-form-input
          disabled
          :value="getFieldValue(gitlabField)"
          class="gl-bg-transparent! gl-text-gray-900!"
        />
      </div>

      <div class="gl-display-table-cell gl-py-3 gl-pr-3">
        <div class="right-arrow">
          <i class="right-arrow-head"></i>
        </div>
      </div>

      <div class="gl-display-table-cell gl-py-3 gl-pr-3 w-30p">
        <gl-dropdown
          :text="selectedValue(gitlabField.mapping)"
          class="gl-w-full"
          :header-text="$options.i18n.selectMappingKey"
        >
          <gl-search-box-by-type @input="setSearchTerm($event, 'searchTerm', gitlabField.key)" />
          <gl-dropdown-item
            v-for="mappingField in filterFields(gitlabField.searchTerm, gitlabField.mappingFields)"
            :key="`${mappingField.key}__mapping`"
            :is-checked="isSelected(gitlabField.mapping, mappingField.key)"
            is-check-item
            @click="setMapping(gitlabField.key, mappingField.key, 'mapping')"
          >
            {{ mappingField.label }}
          </gl-dropdown-item>
          <gl-dropdown-item v-if="noResults(gitlabField.searchTerm, gitlabField.mappingFields)">
            >
            {{ $options.i18n.noResults }}
          </gl-dropdown-item>
        </gl-dropdown>
      </div>

      <div class="gl-display-table-cell gl-py-3 w-30p">
        <gl-dropdown
          v-if="gitlabField.hasFallback"
          :text="selectedValue(gitlabField.fallback)"
          class="gl-w-full"
          :header-text="$options.i18n.selectMappingKey"
        >
          <gl-search-box-by-type
            @input="setSearchTerm($event, 'fallbackSearchTerm', gitlabField.key)"
          />
          <gl-dropdown-item
            v-for="mappingField in filterFields(
              gitlabField.fallbackSearchTerm,
              gitlabField.mappingFields,
            )"
            :key="`${mappingField.key}__fallback`"
            :is-checked="isSelected(gitlabField.fallback, mappingField.key)"
            is-check-item
            @click="setMapping(gitlabField.key, mappingField.key, 'fallback')"
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
