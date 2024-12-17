import { GlAvatarLabeled } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import UserItem from '~/vue_shared/components/list_selector/user_item.vue';

describe('UserItem spec', () => {
  let wrapper;

  const MOCK_USER = { name: 'Admin', username: 'root', avatarUrl: 'some/avatar.jpg' };

  const createComponent = (props) => {
    wrapper = mountExtended(UserItem, {
      propsData: {
        data: MOCK_USER,
        ...props,
      },
      stubs: {
        GlAvatarLabeled,
      },
    });
  };

  const findAvatarLabeled = () => wrapper.findComponent(GlAvatarLabeled);
  const findDeleteButton = () => wrapper.findByTestId('delete-user-btn');

  beforeEach(() => createComponent());

  it('renders AvatarLabeled component', () => {
    expect(findAvatarLabeled().props()).toMatchObject({
      label: 'Admin',
      subLabel: '@root',
    });
    expect(findAvatarLabeled().attributes()).toMatchObject({
      size: '32',
      src: 'some/avatar.jpg',
    });
  });

  it('does not render a delete button by default', () => {
    expect(findDeleteButton().exists()).toBe(false);
  });

  describe('Delete button', () => {
    beforeEach(() => createComponent({ canDelete: true }));

    it('renders a delete button', () => {
      expect(findDeleteButton().exists()).toBe(true);
      expect(findDeleteButton().props('icon')).toBe('remove');
    });

    it('emits a delete event if the delete button is clicked', () => {
      findDeleteButton().vm.$emit('click');

      expect(wrapper.emitted('delete')).toEqual([[MOCK_USER.id]]);
    });
  });
});
