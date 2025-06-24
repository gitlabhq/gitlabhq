<script>
import { s__ } from '~/locale';
import PageHeading from '~/vue_shared/components/page_heading.vue';

export default {
  name: 'AiCatalogAgentsShow',
  components: {
    PageHeading,
  },
  computed: {
    pageTitle() {
      return `${s__('AICatalog|Edit agent')}: ${this.$route.params.id}`;
    },
  },
};
</script>

<template>
  <div>
    <page-heading :heading="pageTitle" />
  </div>
</template>
