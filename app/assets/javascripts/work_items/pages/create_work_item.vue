<script>
import { visitUrl } from '~/lib/utils/url_utility';
import CreateWorkItem from '../components/create_work_item.vue';
import { ROUTES } from '../constants';

export default {
  name: 'CreateWorkItemPage',
  components: {
    CreateWorkItem,
  },
  inject: ['isGroup'],
  props: {
    workItemTypeName: {
      type: String,
      required: false,
      default: null,
    },
  },
  methods: {
    workItemCreated(workItem) {
      if (this.$router) {
        this.$router.push({ name: ROUTES.workItem, params: { iid: workItem.iid } });
      } else {
        visitUrl(workItem.webUrl);
      }
    },
    handleCancelClick() {
      this.$router.go(-1);
    },
  },
};
</script>

<template>
  <create-work-item
    :work-item-type-name="workItemTypeName"
    :is-group="isGroup"
    @workItemCreated="workItemCreated"
  />
</template>
