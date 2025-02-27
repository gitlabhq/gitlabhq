<script>
import ProjectsListItem from '../projects_list/projects_list_item.vue';
import GroupsListItem from '../groups_list/groups_list_item.vue';
import NestedGroupsProjectsList from './nested_groups_projects_list.vue';
import { LIST_ITEM_TYPE_PROJECT } from './constants';

export default {
  components: {
    NestedGroupsProjectsList,
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
  },
  computed: {
    itemComponent() {
      return this.item.type === LIST_ITEM_TYPE_PROJECT ? ProjectsListItem : GroupsListItem;
    },
    itemProps() {
      return this.item.type === LIST_ITEM_TYPE_PROJECT
        ? { project: this.item, showProjectIcon: true }
        : { group: this.item, showGroupIcon: true };
    },
    hasChildren() {
      return this.item.children?.length;
    },
  },
};
</script>

<template>
  <component :is="itemComponent" v-bind="itemProps">
    <template v-if="hasChildren" #nested-items>
      <nested-groups-projects-list :items="item.children" class="gl-pl-4" />
    </template>
  </component>
</template>
