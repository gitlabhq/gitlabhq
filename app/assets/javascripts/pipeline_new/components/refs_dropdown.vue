<script>
import { GlDropdown, GlDropdownItem, GlDropdownSectionHeader, GlSearchBoxByType } from '@gitlab/ui';
import { debounce } from 'lodash';
import axios from '~/lib/utils/axios_utils';
import { BRANCH_REF_TYPE, TAG_REF_TYPE, DEBOUNCE_REFS_SEARCH_MS } from '../constants';
import formatRefs from '../utils/format_refs';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownSectionHeader,
    GlSearchBoxByType,
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
      branches: [],
      tags: [],
    };
  },
  computed: {
    lowerCasedSearchTerm() {
      return this.searchTerm.toLowerCase();
    },
    refShortName() {
      return this.value.shortName;
    },
    hasTags() {
      return this.tags.length > 0;
    },
  },
  watch: {
    searchTerm() {
      this.debouncedLoadRefs();
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

          this.branches = formatRefs(Branches, BRANCH_REF_TYPE);
          this.tags = formatRefs(Tags, TAG_REF_TYPE);
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
    setRefSelected(ref) {
      this.$emit('input', ref);
    },
    isSelected(ref) {
      return ref.fullName === this.value.fullName;
    },
  },
};
</script>
<template>
  <gl-dropdown :text="refShortName" block data-testid="ref-select" @show.once="loadRefs">
    <gl-search-box-by-type
      v-model.trim="searchTerm"
      :is-loading="isLoading"
      :placeholder="__('Search refs')"
      data-testid="search-refs"
    />
    <gl-dropdown-section-header>{{ __('Branches') }}</gl-dropdown-section-header>
    <gl-dropdown-item
      v-for="branch in branches"
      :key="branch.fullName"
      class="gl-font-monospace"
      is-check-item
      :is-checked="isSelected(branch)"
      @click="setRefSelected(branch)"
    >
      {{ branch.shortName }}
    </gl-dropdown-item>
    <gl-dropdown-section-header v-if="hasTags">{{ __('Tags') }}</gl-dropdown-section-header>
    <gl-dropdown-item
      v-for="tag in tags"
      :key="tag.fullName"
      class="gl-font-monospace"
      is-check-item
      :is-checked="isSelected(tag)"
      @click="setRefSelected(tag)"
    >
      {{ tag.shortName }}
    </gl-dropdown-item>
  </gl-dropdown>
</template>
