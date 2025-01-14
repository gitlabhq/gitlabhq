<script>
import SafeHtml from '~/vue_shared/directives/safe_html';
import ListItemDescription from '~/vue_shared/components/resource_lists/list_item_description.vue';

export default {
  name: 'ProjectListItemDescription',
  components: {
    ListItemDescription,
  },
  directives: {
    SafeHtml,
  },
  props: {
    project: {
      type: Object,
      required: true,
    },
  },
  computed: {
    showDescription() {
      return this.project.descriptionHtml && !this.project.archived;
    },
  },
};
</script>

<template>
  <list-item-description v-if="showDescription" :description-html="project.descriptionHtml" />
</template>
