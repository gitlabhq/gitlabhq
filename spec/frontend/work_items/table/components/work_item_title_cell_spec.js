import { GlTruncate } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import WorkItemTitleCell from '~/work_items/table/components/work_item_title_cell.vue';
import { buildWorkItemNode } from '../../board/mock_data';

describe('WorkItemTitleCell', () => {
  let wrapper;

  const item = buildWorkItemNode(1, { title: 'Some work item' });

  const findLink = () => wrapper.findByTestId('work-item-link');

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(WorkItemTitleCell, {
      propsData: { item, ...props },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders the title with the work item type icon', () => {
    expect(wrapper.findComponent(GlTruncate).props('text')).toBe(item.title);
    expect(wrapper.findComponent(WorkItemTypeIcon).props()).toMatchObject({
      workItemType: item.workItemType.name,
      typeIconName: item.workItemType.iconName,
    });
  });

  it('links to the work item', () => {
    expect(findLink().attributes('href')).toBe(item.webPath);
  });

  describe('when the item has no work item type', () => {
    beforeEach(() => {
      createComponent({ props: { item: buildWorkItemNode(1, { workItemType: null }) } });
    });

    it('renders the title without the icon', () => {
      expect(wrapper.findComponent(WorkItemTypeIcon).exists()).toBe(false);
      expect(findLink().exists()).toBe(true);
    });
  });
});
