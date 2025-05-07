<script>
import { s__, sprintf } from '~/locale';
import PageHeading from '~/vue_shared/components/page_heading.vue';

export default {
  name: 'GroupImportHistory',
  components: {
    PageHeading,
  },
  props: {
    groupName: {
      type: String,
      required: true,
    },
  },
  computed: {
    importHistoryHeader() {
      return sprintf(s__('ImportHistory|%{groupName} import history'), {
        groupName: this.groupName,
      });
    },
  },
};
</script>

<template>
  <div>
    <page-heading :heading="importHistoryHeader" />
  </div>
</template>
