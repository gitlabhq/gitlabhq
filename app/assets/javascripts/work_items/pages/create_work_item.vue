<script>
import { visitUrl, getParameterByName, updateHistory, removeParams } from '~/lib/utils/url_utility';
import CreateWorkItem from '../components/create_work_item.vue';
import { ROUTES, RELATED_ITEM_ID_URL_QUERY_PARAM } from '../constants';
import workItemRelatedItemQuery from '../graphql/work_item_related_item.query.graphql';

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
  data() {
    return {
      relatedItem: null,
      relatedItemId: getParameterByName(RELATED_ITEM_ID_URL_QUERY_PARAM),
    };
  },
  apollo: {
    relatedItem: {
      query: workItemRelatedItemQuery,
      variables() {
        return {
          id: this.relatedItemId,
        };
      },
      skip() {
        return !this.relatedItemId;
      },
      update(data) {
        return {
          id: this.relatedItemId,
          reference: data.workItem.reference,
          type: data.workItem.workItemType.name,
        };
      },
      error() {
        // if we cannot find an item with the given id, ignore it and remove it from the url.
        updateHistory({ url: removeParams([RELATED_ITEM_ID_URL_QUERY_PARAM]), replace: true });
      },
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
    :related-item="relatedItem"
    @workItemCreated="workItemCreated"
  />
</template>
