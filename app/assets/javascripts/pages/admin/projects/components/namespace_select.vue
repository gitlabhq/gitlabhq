<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlDropdownDivider,
  GlSearchBoxByType,
  GlLoadingIcon,
} from '@gitlab/ui';
import Api from '~/api';
import { __ } from '~/locale';

export default {
  i18n: {
    dropdownHeader: __('Namespaces'),
    searchPlaceholder: __('Search for Namespace'),
    anyNamespace: __('Any namespace'),
  },
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
    GlLoadingIcon,
    GlSearchBoxByType,
  },
  props: {
    showAny: {
      type: Boolean,
      required: false,
      default: false,
    },
    placeholder: {
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
      selectedNamespaceId: null,
      selectedNamespace: null,
      searchTerm: '',
      isLoading: false,
    };
  },
  computed: {
    selectedNamespaceName() {
      if (this.selectedNamespaceId === null) {
        return this.placeholder;
      }
      return this.selectedNamespace;
    },
  },
  watch: {
    searchTerm() {
      this.fetchNamespaces(this.searchTerm);
    },
  },
  mounted() {
    this.fetchNamespaces();
  },
  methods: {
    fetchNamespaces(filter) {
      this.isLoading = true;
      this.namespaceOptions = [];
      return Api.namespaces(filter, (namespaces) => {
        this.namespaceOptions = namespaces;
        this.isLoading = false;
      });
    },
    selectNamespace(key) {
      this.selectedNamespaceId = this.namespaceOptions[key].id;
      this.selectedNamespace = this.getNamespaceString(this.namespaceOptions[key]);
      this.$emit('setNamespace', this.selectedNamespaceId);
    },
    selectAnyNamespace() {
      this.selectedNamespaceId = null;
      this.selectedNamespace = null;
      this.$emit('setNamespace', null);
    },
    getNamespaceString(namespace) {
      return `${namespace.kind}: ${namespace.full_path}`;
    },
  },
};
</script>

<template>
  <div class="gl-display-flex">
    <input
      v-if="fieldName"
      :name="fieldName"
      :value="selectedNamespaceId"
      type="hidden"
      data-testid="hidden-input"
    />
    <gl-dropdown
      :text="selectedNamespaceName"
      :header-text="$options.i18n.dropdownHeader"
      toggle-class="dropdown-menu-toggle large"
      data-testid="namespace-dropdown"
      :right="true"
    >
      <template #header>
        <gl-search-box-by-type
          v-model.trim="searchTerm"
          class="namespace-search-box"
          debounce="250"
          :placeholder="$options.i18n.searchPlaceholder"
        />
      </template>

      <template v-if="showAny">
        <gl-dropdown-item @click="selectAnyNamespace">
          {{ $options.i18n.anyNamespace }}
        </gl-dropdown-item>
        <gl-dropdown-divider />
      </template>

      <gl-loading-icon v-if="isLoading" />

      <gl-dropdown-item
        v-for="(namespace, key) in namespaceOptions"
        :key="namespace.id"
        @click="selectNamespace(key)"
      >
        {{ getNamespaceString(namespace) }}
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>

<style scoped>
/* workaround position: relative imposed by .top-area .nav-controls */
.namespace-search-box >>> input {
  position: static;
}
</style>
