import { GlAvatar } from '@gitlab/ui';
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
    });
  };

  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findDeleteButton = () => wrapper.findByRole('button', { name: 'Delete Admin' });

  beforeEach(() => createComponent());

  it('renders an Avatar component', () => {
    expect(findAvatar().props('size')).toBe(32);
    expect(findAvatar().attributes()).toMatchObject({
      src: MOCK_USER.avatarUrl,
      alt: MOCK_USER.name,
    });
  });

  it('renders a name and username', () => {
    expect(wrapper.text()).toContain('Admin');
    expect(wrapper.text()).toContain('@root');
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
      findDeleteButton().trigger('click');

      expect(wrapper.emitted('delete')).toEqual([[MOCK_USER.username]]);
    });
  });
});
