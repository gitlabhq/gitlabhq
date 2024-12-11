import { GlAvatarLabeled } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GroupItem from '~/vue_shared/components/list_selector/group_item.vue';
import HiddenGroupsItem from 'ee_component/approvals/components/hidden_groups_item.vue';

describe('GroupItem spec', () => {
  let wrapper;

  const MOCK_GROUP = { id: 123, fullName: 'Group 1', name: 'group1', avatarUrl: 'some/avatar.jpg' };

  const createComponent = (props, options) => {
    wrapper = shallowMountExtended(GroupItem, {
      propsData: {
        data: MOCK_GROUP,
        ...props,
      },
      ...options,
    });
  };

  const findAvatarLabeled = () => wrapper.findComponent(GlAvatarLabeled);
  const findDeleteButton = () => wrapper.findByTestId('delete-group-btn');

  beforeEach(() => createComponent());

  it('renders AvatarLabeled component', () => {
    expect(findAvatarLabeled().props()).toMatchObject({
      label: 'Group 1',
      subLabel: '@group1',
    });
    expect(findAvatarLabeled().attributes()).toMatchObject({
      size: '32',
      src: 'some/avatar.jpg',
    });
  });

  it('does not render a delete button by default', () => {
    expect(findDeleteButton().exists()).toBe(false);
  });

  describe('hidden groups', () => {
    beforeEach(() =>
      createComponent(
        { data: { ...MOCK_GROUP, type: 'hidden_groups' } },
        { stubs: { HiddenGroupsItem } },
      ),
    );

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
      findDeleteButton().vm.$emit('click');

      expect(wrapper.emitted('delete')).toEqual([[MOCK_GROUP.id]]);
    });
  });
});
