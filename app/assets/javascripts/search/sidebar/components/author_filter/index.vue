<script>
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import { GlFormCheckbox, GlTooltipDirective } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { s__ } from '~/locale';
import AjaxCache from '~/lib/utils/ajax_cache';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import FilterDropdown from '~/search/sidebar/components/shared/filter_dropdown.vue';

import {
  SEARCH_ICON,
  USER_ICON,
  AUTHOR_ENDPOINT_PATH,
  AUTHOR_PARAM,
  NOT_AUTHOR_PARAM,
} from '../../constants';

export default {
  name: 'AuthorFilter',
  components: {
    FilterDropdown,
    GlFormCheckbox,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  data() {
    return {
      authors: [],
      error: '',
      toggleState: false,
      selectedAuthorName: '',
      selectedAuthorValue: '',
      isLoading: false,
      searchTerm: '',
    };
  },
  i18n: {
    toggleTooltip: s__('GlobalSearch|Toggle if results have source branch included or excluded'),
    author: s__('GlobalSearch|Author'),
    search: s__('GlobalSearch|Search'),
    authorNotIncluded: s__('GlobalSearch|Author not included'),
  },
  computed: {
    ...mapState(['groupInitialJson', 'projectInitialJson', 'query']),
    showDropdownPlaceholderText() {
      return this.selectedAuthorName ? this.selectedAuthorName : this.$options.i18n.search;
    },
    showDropdownPlaceholderIcon() {
      return this.selectedAuthorName ? USER_ICON : SEARCH_ICON;
    },
  },
  watch: {
    authors(newAuthors) {
      if (newAuthors.length > 0 && this.selectedAuthorValue) {
        this.selectedAuthorName = this.convertValueToName(this.selectedAuthorValue);
      }
      this.handleSelected(this.selectedAuthorValue);
    },
  },
  mounted() {
    this.selectedAuthorValue = this.query?.[AUTHOR_PARAM] || this.query?.[NOT_AUTHOR_PARAM];
    this.toggleState = Boolean(this.query?.[NOT_AUTHOR_PARAM]);
    if (this.selectedAuthorValue) {
      this.getCachedDropdownData();
    }
  },
  methods: {
    ...mapActions(['setQuery', 'applyQuery']),
    getDropdownAPIEndpoint() {
      const endpoint = `${gon.relative_url_root || ''}${AUTHOR_ENDPOINT_PATH}`;
      const params = {
        current_user: true,
        active: true,
        group_id: this.groupInitialJson?.id || null,
        project_id: this.projectInitialJson?.id || null,
        search: this.searchTerm,
      };
      return mergeUrlParams(params, endpoint);
    },
    convertToListboxItems(data) {
      return data.map((item) => ({
        ...item,
        text: item.name,
        value: item.username,
      }));
    },
    async getCachedDropdownData() {
      this.isLoading = true;
      try {
        const data = await AjaxCache.retrieve(this.getDropdownAPIEndpoint());
        this.error = '';
        this.isLoading = false;
        this.authors = this.convertToListboxItems(data);
      } catch (error) {
        Sentry.captureException(error);
        this.isLoading = false;
        this.error = error.message;
      }
    },
    handleSelected(selectedAuthorValue) {
      this.selectedAuthorName = this.convertValueToName(selectedAuthorValue);
      this.selectedAuthorValue = selectedAuthorValue;

      if (this.toggleState) {
        this.setNotAuthorParam(selectedAuthorValue);
        return;
      }
      this.setAuthorParam(selectedAuthorValue);
    },
    setAuthorParam(selectedAuthorValue) {
      this.setQuery({ key: AUTHOR_PARAM, value: selectedAuthorValue });
      this.setQuery({ key: NOT_AUTHOR_PARAM, value: '' });
    },
    setNotAuthorParam(selectedAuthorValue) {
      this.setQuery({ key: NOT_AUTHOR_PARAM, value: selectedAuthorValue });
      this.setQuery({ key: AUTHOR_PARAM, value: '' });
    },
    convertValueToName(selectedAuthorValue) {
      const authorObj = this.authors.find((item) => item.value === selectedAuthorValue);
      return authorObj?.text || selectedAuthorValue;
    },
    changeCheckboxInput(state) {
      this.toggleState = state;
      this.handleSelected(this.selectedAuthorValue);
    },
    handleSearch(searchTerm) {
      this.searchTerm = searchTerm;
      this.getCachedDropdownData();
    },
    handleReset() {
      this.toggleState = false;
      this.setQuery({ key: AUTHOR_PARAM, value: '' });
      this.setQuery({ key: NOT_AUTHOR_PARAM, value: '' });
      this.applyQuery();
    },
  },
};
</script>

<template>
  <div class="gl-relative gl-pb-0 md:gl-pt-0">
    <div class="gl-mb-2 gl-text-sm gl-font-bold" data-testid="author-filter-title">
      {{ $options.i18n.author }}
    </div>
    <filter-dropdown
      :list-data="authors"
      :error="error"
      :header-text="$options.i18n.author"
      :search-text="showDropdownPlaceholderText"
      :selected-item="selectedAuthorValue"
      :icon="showDropdownPlaceholderIcon"
      :is-loading="isLoading"
      :has-api-search="true"
      @search="handleSearch"
      @selected="handleSelected"
      @shown="getCachedDropdownData"
      @reset="handleReset"
    />
    <gl-form-checkbox
      v-model="toggleState"
      class="gl-mb-0 gl-inline-flex gl-w-full gl-grow gl-justify-between gl-pt-4"
      @input="changeCheckboxInput"
    >
      <span v-gl-tooltip="$options.i18n.toggleTooltip" data-testid="author-filter-tooltip">
        {{ $options.i18n.authorNotIncluded }}
      </span>
    </gl-form-checkbox>
  </div>
</template>
