import { GlForm } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import WorkItemBulkEditLabels from '~/work_items/components/work_item_bulk_edit/work_item_bulk_edit_labels.vue';
import WorkItemBulkEditSidebar from '~/work_items/components/work_item_bulk_edit/work_item_bulk_edit_sidebar.vue';

describe('WorkItemBulkEditSidebar component', () => {
  let wrapper;

  const checkedItems = [
    { id: 'gid://gitlab/WorkItem/1', title: 'Work Item 1' },
    { id: 'gid://gitlab/WorkItem/2', title: 'Work Item 2' },
  ];

  const createComponent = () => {
    wrapper = shallowMount(WorkItemBulkEditSidebar, {
      propsData: {
        checkedItems,
        fullPath: 'group/project',
        isGroup: false,
      },
    });
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findAddLabelsComponent = () => wrapper.findAllComponents(WorkItemBulkEditLabels).at(0);
  const findRemoveLabelsComponent = () => wrapper.findAllComponents(WorkItemBulkEditLabels).at(1);

  beforeEach(() => {
    createComponent();
  });

  describe('form', () => {
    it('renders', () => {
      expect(findForm().attributes('id')).toBe('work-item-list-bulk-edit');
    });

    it('emits "bulk-update" event when submitted', () => {
      const addLabelIds = ['gid://gitlab/Label/1'];
      const removeLabelIds = ['gid://gitlab/Label/2'];

      findAddLabelsComponent().vm.$emit('select', addLabelIds);
      findRemoveLabelsComponent().vm.$emit('select', removeLabelIds);
      findForm().vm.$emit('submit', { preventDefault: () => {} });

      expect(wrapper.emitted('bulk-update')).toEqual([
        [
          {
            ids: checkedItems.map((item) => item.id),
            addLabelIds,
            removeLabelIds,
          },
        ],
      ]);
      expect(findAddLabelsComponent().props('selectedLabelsIds')).toEqual([]);
      expect(findRemoveLabelsComponent().props('selectedLabelsIds')).toEqual([]);
    });
  });

  describe('"Add labels" component', () => {
    it('renders', () => {
      expect(findAddLabelsComponent().props()).toMatchObject({
        formLabel: 'Add labels',
        formLabelId: 'bulk-update-add-labels',
      });
    });

    it('updates labels to add when "Add labels" component emits "select" event', async () => {
      const labelIds = ['gid://gitlab/Label/1', 'gid://gitlab/Label/2'];

      findAddLabelsComponent().vm.$emit('select', labelIds);
      await nextTick();

      expect(findAddLabelsComponent().props('selectedLabelsIds')).toEqual(labelIds);
    });
  });

  describe('"Remove labels" component', () => {
    it('renders', () => {
      expect(findRemoveLabelsComponent().props()).toMatchObject({
        formLabel: 'Remove labels',
        formLabelId: 'bulk-update-remove-labels',
      });
    });

    it('updates labels to remove when "Remove labels" component emits "select" event', async () => {
      const labelIds = ['gid://gitlab/Label/1', 'gid://gitlab/Label/2'];

      findRemoveLabelsComponent().vm.$emit('select', labelIds);
      await nextTick();

      expect(findRemoveLabelsComponent().props('selectedLabelsIds')).toEqual(labelIds);
    });
  });
});
