<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { n__ } from '~/locale';

export default {
  name: 'VariableValuesListbox',
  components: {
    GlCollapsibleListbox,
  },
  props: {
    selected: {
      type: String,
      required: true,
    },
    items: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      searchTerm: '',
    };
  },
  computed: {
    searchSummary() {
      return n__(
        'CiVariables|%d value found',
        'CiVariables|%d values found',
        this.filteredItems.length,
      );
    },
    filteredItems() {
      if (this.searchTerm) {
        return fuzzaldrinPlus.filter(this.items, this.searchTerm, {
          key: ['text'],
        });
      }
      return this.items;
    },
  },
  methods: {
    onSearch(searchTerm) {
      this.searchTerm = searchTerm.trim().toLowerCase();
    },
  },
};
</script>
<template>
  <gl-collapsible-listbox
    :items="filteredItems"
    :toggle-text="selected"
    :selected="selected"
    :search-placeholder="s__('CiVariables|Search values')"
    :no-results-text="s__('CiVariables|No matching values')"
    searchable
    block
    fluid-width
    @search="onSearch"
    @select="$emit('select', $event)"
  >
    <template #search-summary-sr-only>
      {{ searchSummary }}
    </template>
  </gl-collapsible-listbox>
</template>
