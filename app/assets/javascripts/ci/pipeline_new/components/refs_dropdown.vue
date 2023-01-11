<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { debounce } from 'lodash';
import axios from '~/lib/utils/axios_utils';
import { DEBOUNCE_REFS_SEARCH_MS } from '../constants';
import { formatListBoxItems, searchByFullNameInListboxOptions } from '../utils/format_refs';

export default {
  components: {
    GlCollapsibleListbox,
  },
  inject: ['projectRefsEndpoint'],
  props: {
    value: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      isLoading: false,
      searchTerm: '',
      listBoxItems: [],
    };
  },
  computed: {
    lowerCasedSearchTerm() {
      return this.searchTerm.toLowerCase();
    },
    refShortName() {
      return this.value.shortName;
    },
  },
  methods: {
    loadRefs() {
      this.isLoading = true;

      axios
        .get(this.projectRefsEndpoint, {
          params: {
            search: this.lowerCasedSearchTerm,
          },
        })
        .then(({ data }) => {
          // Note: These keys are uppercase in API
          const { Branches = [], Tags = [] } = data;

          this.listBoxItems = formatListBoxItems(Branches, Tags);
        })
        .catch((e) => {
          this.$emit('loadingError', e);
        })
        .finally(() => {
          this.isLoading = false;
        });
    },
    debouncedLoadRefs: debounce(function debouncedLoadRefs() {
      this.loadRefs();
    }, DEBOUNCE_REFS_SEARCH_MS),
    setRefSelected(refFullName) {
      const ref = searchByFullNameInListboxOptions(refFullName, this.listBoxItems);
      this.$emit('input', ref);
    },
    setSearchTerm(searchQuery) {
      this.searchTerm = searchQuery?.trim();
      this.debouncedLoadRefs();
    },
  },
};
</script>
<template>
  <gl-collapsible-listbox
    class="gl-w-full gl-font-monospace"
    data-testid="ref-select"
    :items="listBoxItems"
    :searchable="true"
    :searching="isLoading"
    :search-placeholder="__('Search refs')"
    :selected="value.fullName"
    toggle-class="gl-flex-direction-column gl-align-items-stretch!"
    :toggle-text="refShortName"
    @search="setSearchTerm"
    @select="setRefSelected"
    @shown.once="loadRefs"
  />
</template>
