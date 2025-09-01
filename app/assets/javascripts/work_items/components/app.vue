<script>
import WorkItemMetadataProvider from '~/work_items/components/work_item_metadata_provider.vue';

export default {
  components: {
    WorkItemMetadataProvider,
  },
  props: {
    rootPageFullPath: {
      type: String,
      required: false,
      default: undefined,
    },
    withTabs: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    pageKey() {
      return this.$route.params.iid || this.$route.name;
    },
  },
};
</script>

<template>
  <work-item-metadata-provider :full-path="rootPageFullPath">
    <router-view
      :key="pageKey"
      :root-page-full-path="rootPageFullPath"
      :with-tabs="withTabs"
      class="work-item-router-view"
      data-testid="work-item-router-view"
    />
  </work-item-metadata-provider>
</template>
