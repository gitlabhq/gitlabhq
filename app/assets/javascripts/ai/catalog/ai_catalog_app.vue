<script>
import PageHeading from '~/vue_shared/components/page_heading.vue';
import AiCatalogNavTabs from './components/ai_catalog_nav_tabs.vue';

export default {
  name: 'AiCatalogApp',
  components: {
    AiCatalogNavTabs,
    PageHeading,
  },
};
</script>

<template>
  <div>
    <page-heading :heading="s__('AICatalog|AI Catalog')" />
    <ai-catalog-nav-tabs />
    <router-view />
  </div>
</template>
