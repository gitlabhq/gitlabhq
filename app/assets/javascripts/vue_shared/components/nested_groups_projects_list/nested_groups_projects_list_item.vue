<script>
import { GlButton, GlLink } from '@gitlab/ui';
import { sprintf, s__, n__ } from '~/locale';
import {
  TIMESTAMP_TYPES,
  TIMESTAMP_TYPE_CREATED_AT,
} from '~/vue_shared/components/resource_lists/constants';
import ProjectsListItem from '../projects_list/projects_list_item.vue';
import GroupsListItem from '../groups_list/groups_list_item.vue';
import { LIST_ITEM_TYPE_PROJECT, MAX_CHILDREN_COUNT } from './constants';

export default {
  components: {
    GlButton,
    GlLink,
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
    timestampType: {
      type: String,
      required: false,
      default: TIMESTAMP_TYPE_CREATED_AT,
      validator(value) {
        return TIMESTAMP_TYPES.includes(value);
      },
    },
    /**
     * Allows the parent component to override `isExpanded`.
     * This is needed when searching as we want the tree to be open after searching.
     */
    expandedOverride: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isExpanded: this.expandedOverride,
    };
  },
  computed: {
    itemComponent() {
      return this.item.type === LIST_ITEM_TYPE_PROJECT ? ProjectsListItem : GroupsListItem;
    },
    nestedItemsContainerId() {
      return `nested-items-container-${this.item.id}`;
    },
    nestedItemsContainerClasses() {
      const baseClasses = ['gl-pl-6'];

      if (!this.showChildren) {
        return [...baseClasses, 'gl-hidden'];
      }

      return baseClasses;
    },
    itemProps() {
      const sharedProps = {
        listItemClass: this.item.hasChildren ? null : 'gl-pl-7',
        timestampType: this.timestampType,
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
    hasMoreChildren() {
      return this.item.childrenCount > MAX_CHILDREN_COUNT;
    },
    moreChildrenLinkText() {
      return n__(
        'View all (%d more item)',
        'View all (%d more items)',
        this.item.childrenCount - this.item.children.length,
      );
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
      return this.item.children;
    },
  },
  watch: {
    expandedOverride(newValue) {
      this.isExpanded = newValue;
    },
  },
  methods: {
    onNestedItemsToggleClick() {
      this.isExpanded = !this.isExpanded;

      if (!this.item.children?.length) {
        this.$emit('load-children', this.item.id);
      }
    },
    onRefetch() {
      this.$emit('refetch');
    },
  },
};
</script>

<template>
  <component :is="itemComponent" v-bind="itemProps" @refetch="onRefetch">
    <template v-if="item.hasChildren" #children-toggle>
      <gl-button
        v-bind="expandButtonProps"
        data-testid="nested-groups-project-list-item-toggle-button"
        @click="onNestedItemsToggleClick"
      />
    </template>
    <template v-if="item.hasChildren" #children>
      <!-- eslint-disable-next-line vue/no-undef-components -->
      <nested-groups-projects-list
        :id="nestedItemsContainerId"
        :items="nestedGroupsProjectsListItems"
        :timestamp-type="timestampType"
        :expanded-override="expandedOverride"
        :class="nestedItemsContainerClasses"
        @load-children="$emit('load-children', $event)"
        @refetch="onRefetch"
      >
        <li v-if="hasMoreChildren" class="gl-border-b gl-py-4 gl-pl-7">
          <div class="gl-flex gl-h-7 gl-items-center">
            <gl-link :href="item.webUrl" data-testid="more-children-link">
              {{ moreChildrenLinkText }}
            </gl-link>
          </div>
        </li>
      </nested-groups-projects-list>
    </template>
  </component>
</template>
