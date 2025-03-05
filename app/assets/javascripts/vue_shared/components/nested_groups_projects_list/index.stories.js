import NestedGroupsProjectsList from './nested_groups_projects_list.vue';
import { items as mockItems } from './mock_data';
import { LIST_ITEM_TYPE_GROUP } from './constants';

export default {
  component: NestedGroupsProjectsList,
  title: 'vue_shared/nested_groups_projects_list',
};

const Template = () => ({
  components: { NestedGroupsProjectsList },
  data() {
    return {
      items: mockItems,
    };
  },
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
  template: `<nested-groups-projects-list :items="items" @load-children="onLoadChildren" />`,
});

export const Default = Template.bind({});
Default.args = {};
