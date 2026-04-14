import { GlIcon, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemParentMetadata from '~/work_items/components/shared/work_item_parent_metadata.vue';
import WorkItemPopover from '~/issuable/popover/components/work_item_popover.vue';
import { mockParentWorkItem } from 'ee_else_ce_jest/work_items/mock_data';

describe('WorkItemParentMetadata', () => {
  let wrapper;

  const mockParent = mockParentWorkItem;

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findLink = () => wrapper.findComponent(GlLink);
  const findPopover = () => wrapper.findComponent(WorkItemPopover);

  const createComponent = (parent = mockParent) => {
    wrapper = shallowMountExtended(WorkItemParentMetadata, {
      propsData: {
        parent,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders parent icon', () => {
    expect(findIcon().exists()).toBe(true);
    expect(findIcon().props('name')).toBe('work-item-parent');
  });

  it('renders parent title as a link', () => {
    expect(findLink().exists()).toBe(true);
    expect(findLink().text()).toBe(mockParentWorkItem.title);
    expect(findLink().attributes('href')).toBe(mockParentWorkItem.webUrl);
  });

  it('renders parent popover', () => {
    expect(findPopover().exists()).toBe(true);
    expect(findPopover().props()).toMatchObject({
      cachedTitle: 'Parent Work Item',
      iid: '100',
      namespacePath: 'gitlab-org/gitlab-test',
    });
  });

  describe('parentIid', () => {
    it('reads iid directly from parent iid field', () => {
      createComponent({
        ...mockParent,
        iid: '42',
      });

      expect(findPopover().props('iid')).toBe('42');
    });

    it('returns empty string when iid is missing', () => {
      createComponent({
        ...mockParent,
        iid: null,
      });

      expect(findPopover().props('iid')).toBe('');
    });
  });

  describe('parentNamespace', () => {
    it('reads namespace from parent namespace.fullPath', () => {
      createComponent({
        ...mockParent,
        namespace: {
          id: 'gid://gitlab/Group/2',
          fullPath: 'my-org/my-project',
          __typename: 'Project',
        },
      });

      expect(findPopover().props('namespacePath')).toBe('my-org/my-project');
    });
  });
});
