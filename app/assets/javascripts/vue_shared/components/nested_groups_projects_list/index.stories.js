import Vue from 'vue';
import {
  TIMESTAMP_TYPE_UPDATED_AT,
  TIMESTAMP_TYPES,
} from '~/vue_shared/components/resource_lists/constants';
import NestedGroupsProjectsList from './nested_groups_projects_list.vue';
import NestedGroupsProjectsListItem from './nested_groups_projects_list_item.vue';
import { items as mockItems } from './mock_data';
import { LIST_ITEM_TYPE_GROUP } from './constants';

// We need to globally render components to avoid circular references
// https://v2.vuejs.org/v2/guide/components-edge-cases.html#Circular-References-Between-Components
Vue.component('NestedGroupsProjectsList', NestedGroupsProjectsList);
Vue.component('NestedGroupsProjectsListItem', NestedGroupsProjectsListItem);

export default {
  component: NestedGroupsProjectsList,
  title: 'vue_shared/nested_groups_projects_list',
  argTypes: {
    timestampType: {
      control: {
        type: 'select',
        options: TIMESTAMP_TYPES,
      },
    },
    items: {
      control: false,
    },
    'load-children': {
      control: false,
    },
  },
};

const Template = (args, { argTypes }) => ({
  components: { NestedGroupsProjectsList },
  props: Object.keys(argTypes),
  methods: {
    findItemById(items, id) {
      if (!items?.length) {
        return null;
      }

      for (let i = 0; i < items.length; i += 1) {
        const item = items[i];

        // Check if current item has the ID we're looking for
        if (item.id === id) {
          return item;
        }

        // If this is a group, recursively search its children
        if (item.type === LIST_ITEM_TYPE_GROUP && item.children?.length) {
          return this.findItemById(item.children, id);
        }
      }

      // Item not found at any level
      return null;
    },
    async onLoadChildren(id) {
      const item = this.findItemById(this.items, id);

      if (!item) {
        return;
      }

      item.childrenLoading = true;

      // Pretend we are waiting for an API request
      await new Promise((resolve) => {
        setTimeout(resolve, 1000);
      });

      item.childrenLoading = false;
      item.children = item.childrenToLoad;
    },
  },
  template: `
    <nested-groups-projects-list
      :items="items"
      :timestamp-type="timestampType"
      @load-children="onLoadChildren"
    />
  `,
});

export const Default = Template.bind({});
Default.args = {
  items: mockItems,
  timestampType: TIMESTAMP_TYPE_UPDATED_AT,
};
