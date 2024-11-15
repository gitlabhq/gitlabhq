import { GlAvatar } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import GroupItem from '~/vue_shared/components/list_selector/group_item.vue';
import HiddenGroupsItem from 'ee_component/approvals/components/hidden_groups_item.vue';

describe('GroupItem spec', () => {
  let wrapper;

  const MOCK_GROUP = { id: 123, fullName: 'Group 1', name: 'group1', avatarUrl: 'some/avatar.jpg' };

  const createComponent = (props) => {
    wrapper = mountExtended(GroupItem, {
      propsData: {
        data: MOCK_GROUP,
        ...props,
      },
    });
  };

  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findDeleteButton = () => wrapper.findByTestId('delete-group-btn');

  beforeEach(() => createComponent());

  it('renders an Avatar component', () => {
    expect(findAvatar().props('size')).toBe(32);
    expect(findAvatar().attributes()).toMatchObject({
      src: MOCK_GROUP.avatarUrl,
      alt: MOCK_GROUP.fullName,
    });
  });

  it('renders a fullName and name', () => {
    expect(wrapper.text()).toContain('Group 1');
    expect(wrapper.text()).toContain('group1');
  });

  it('does not render a delete button by default', () => {
    expect(findDeleteButton().exists()).toBe(false);
  });

  describe('hidden groups', () => {
    beforeEach(() => createComponent({ data: { ...MOCK_GROUP, type: 'hidden_groups' } }));

    const findHiddenGroupsItem = () => wrapper.findComponent(HiddenGroupsItem);

    it('renders a hidden groups item component', () => {
      expect(findHiddenGroupsItem().exists()).toBe(true);
    });
  });

  describe('Delete button', () => {
    beforeEach(() => createComponent({ canDelete: true }));

    it('renders a delete button', () => {
      expect(findDeleteButton().exists()).toBe(true);
      expect(findDeleteButton().props('icon')).toBe('remove');
    });

    it('emits a delete event if the delete button is clicked', () => {
      findDeleteButton().trigger('click');

      expect(wrapper.emitted('delete')).toEqual([[MOCK_GROUP.id]]);
    });
  });
});
