<script>
import { visitUrl } from '~/lib/utils/url_utility';
import CreateWorkItem from '../components/create_work_item.vue';

export default {
  name: 'CreateWorkItemPage',
  components: {
    CreateWorkItem,
  },
  methods: {
    workItemCreated(workItem) {
      visitUrl(workItem.webUrl);
    },
    handleCancelClick() {
      this.$router.go(-1);
    },
  },
};
</script>

<template>
  <create-work-item @workItemCreated="workItemCreated" />
</template>
