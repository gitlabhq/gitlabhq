<script>
import { GlButton } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import ProjectsListItem from '../projects_list/projects_list_item.vue';
import GroupsListItem from '../groups_list/groups_list_item.vue';
import NestedGroupsProjectsList from './nested_groups_projects_list.vue';
import { LIST_ITEM_TYPE_PROJECT } from './constants';

export default {
  components: {
    GlButton,
    NestedGroupsProjectsList,
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isExpanded: false,
    };
  },
  computed: {
    itemComponent() {
      return this.item.type === LIST_ITEM_TYPE_PROJECT ? ProjectsListItem : GroupsListItem;
    },
    nestedItemsContainerId() {
      return `nested-items-container-${this.item.id}`;
    },
    itemProps() {
      const sharedProps = {
        listItemClass: this.item.hasChildren ? null : 'gl-pl-7',
      };

      return this.item.type === LIST_ITEM_TYPE_PROJECT
        ? {
            ...sharedProps,
            project: this.item,
            showProjectIcon: true,
          }
        : {
            ...sharedProps,
            group: this.item,
            showGroupIcon: true,
          };
    },
    showChildren() {
      return this.isExpanded && this.item.children?.length;
    },
    expandButtonProps() {
      return {
        'aria-label': sprintf(s__('Groups|Show children of %{avatarLabel}'), {
          avatarLabel: this.item.avatarLabel,
        }),
        category: 'tertiary',
        icon: this.showChildren ? 'chevron-down' : 'chevron-right',
        loading: this.item.childrenLoading,
        'aria-expanded': this.showChildren ? 'true' : 'false',
        'aria-controls': this.nestedItemsContainerId,
      };
    },
    nestedGroupsProjectsListItems() {
      if (this.showChildren) {
        return this.item.children;
      }

      return [];
    },
  },
  methods: {
    onNestedItemsToggleClick() {
      this.isExpanded = !this.isExpanded;

      if (!this.item.children?.length) {
        this.$emit('load-children', this.item.id);
      }
    },
  },
};
</script>

<template>
  <component :is="itemComponent" v-bind="itemProps">
    <template v-if="item.hasChildren" #children-toggle>
      <gl-button v-bind="expandButtonProps" @click="onNestedItemsToggleClick" />
    </template>
    <template v-if="item.hasChildren" #children>
      <nested-groups-projects-list
        :id="nestedItemsContainerId"
        :items="nestedGroupsProjectsListItems"
        class="gl-pl-6"
        @load-children="$emit('load-children', $event)"
      />
    </template>
  </component>
</template>
