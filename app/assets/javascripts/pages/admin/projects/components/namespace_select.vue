<script>
import { debounce } from 'lodash';
import { GlCollapsibleListbox } from '@gitlab/ui';
import Api from '~/api';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import { __ } from '~/locale';

export default {
  i18n: {
    headerText: __('Namespaces'),
    searchPlaceholder: __('Search for Namespace'),
    reset: __('Clear'),
  },
  components: {
    GlCollapsibleListbox,
  },
  props: {
    origSelectedId: {
      type: String,
      required: false,
      default: '',
    },
    origSelectedText: {
      type: String,
      required: false,
      default: '',
    },
    toggleTextPlaceholder: {
      type: String,
      required: false,
      default: __('Namespace'),
    },
    fieldName: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      namespaceOptions: [],
      selectedNamespaceId: this.origSelectedId,
      selectedNamespaceText: this.origSelectedText,
      searchTerm: '',
      isLoading: false,
    };
  },
  computed: {
    toggleText() {
      return this.selectedNamespaceText || this.toggleTextPlaceholder;
    },
  },
  watch: {
    selectedNamespaceId(val) {
      if (!val) {
        this.selectedNamespaceText = null;
      }

      this.selectedNamespaceText = this.namespaceOptions.find(({ value }) => value === val)?.text;
    },
  },
  mounted() {
    this.fetchNamespaces();
  },
  methods: {
    fetchNamespaces() {
      this.isLoading = true;
      this.namespaceOptions = [];

      return Api.namespaces(this.searchTerm, (namespaces) => {
        this.namespaceOptions = this.formatNamespaceOptions(namespaces);
        this.isLoading = false;
      });
    },
    formatNamespaceOptions(namespaces) {
      if (!namespaces) {
        return [];
      }

      return namespaces.map((namespace) => {
        return {
          value: String(namespace.id),
          text: this.getNamespaceString(namespace),
        };
      });
    },
    selectNamespace(value) {
      this.selectedNamespaceId = value;
      this.$emit('setNamespace', this.selectedNamespaceId);
    },
    getNamespaceString(namespace) {
      return `${namespace.kind}: ${namespace.full_path}`;
    },
    search: debounce(function debouncedSearch(searchQuery) {
      this.searchTerm = searchQuery?.trim();
      this.fetchNamespaces();
    }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS),
    onReset() {
      this.selectedNamespaceId = null;
      this.$emit('setNamespace', null);
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-w-full">
    <input
      v-if="fieldName"
      :name="fieldName"
      :value="selectedNamespaceId"
      type="hidden"
      data-testid="hidden-input"
    />
    <gl-collapsible-listbox
      :items="namespaceOptions"
      :header-text="$options.i18n.headerText"
      :reset-button-label="$options.i18n.reset"
      :toggle-text="toggleText"
      :search-placeholder="$options.i18n.searchPlaceholder"
      :searching="isLoading"
      :selected="selectedNamespaceId"
      toggle-class="gl-w-full gl-flex-col !gl-items-stretch"
      searchable
      @reset="onReset"
      @search="search"
      @select="selectNamespace"
    />
  </div>
</template>
