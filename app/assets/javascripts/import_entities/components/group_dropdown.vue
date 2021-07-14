<script>
import { GlDropdown, GlSearchBoxByType } from '@gitlab/ui';

export default {
  components: {
    GlDropdown,
    GlSearchBoxByType,
  },
  inheritAttrs: false,
  props: {
    namespaces: {
      type: Array,
      required: true,
    },
  },
  data() {
    return { searchTerm: '' };
  },
  computed: {
    filteredNamespaces() {
      return this.namespaces.filter((ns) =>
        ns.toLowerCase().includes(this.searchTerm.toLowerCase()),
      );
    },
  },
};
</script>
<template>
  <gl-dropdown
    toggle-class="gl-rounded-top-right-none! gl-rounded-bottom-right-none!"
    class="import-entities-namespace-dropdown gl-h-7 gl-flex-fill-1"
    data-qa-selector="target_namespace_selector_dropdown"
    v-bind="$attrs"
  >
    <template #header>
      <gl-search-box-by-type v-model.trim="searchTerm" />
    </template>
    <slot :namespaces="filteredNamespaces"></slot>
  </gl-dropdown>
</template>
