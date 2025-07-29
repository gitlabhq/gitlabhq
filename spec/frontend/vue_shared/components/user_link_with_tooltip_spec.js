import { GlAvatarLink, GlAvatar } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import UserLinkWithTooltip from '~/vue_shared/components/user_link_with_tooltip.vue';

describe('UserTooltip', () => {
  let wrapper;

  const defaultProps = {
    avatar: {
      name: 'John Doe',
      username: 'johndoe',
      webUrl: 'https://gitlab.com/johndoe',
      avatarUrl: 'https://gitlab.com/uploads/user/avatar/123/avatar.png',
    },
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(UserLinkWithTooltip, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findAvatarLink = () => wrapper.findComponent(GlAvatarLink);
  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findTooltipLabel = () => wrapper.findByTestId('user-link-tooltip-label');
  const findTooltipName = () => wrapper.findByTestId('user-link-tooltip-name');
  const findTooltipUsername = () => wrapper.findByTestId('user-link-tooltip-username');

  describe('GlAvatarLink', () => {
    it('passes correct href prop', () => {
      createComponent();

      expect(findAvatarLink().attributes('href')).toBe('https://gitlab.com/johndoe');
    });

    it('passes correct aria-label prop', () => {
      createComponent();

      expect(findAvatarLink().attributes('aria-label')).toBe('John Doe');
    });
  });

  describe('GlAvatar', () => {
    it('passes correct props', () => {
      createComponent();

      expect(findAvatar().props('alt')).toBe('John Doe');
      expect(findAvatar().props('src')).toBe(
        'https://gitlab.com/uploads/user/avatar/123/avatar.png',
      );
      expect(findAvatar().props('size')).toBe(16);
    });
  });

  describe('GlTooltip', () => {
    it('renders avatar name in tooltip', () => {
      createComponent();

      expect(findTooltipName().text()).toBe('John Doe');
    });

    it('renders username in tooltip when provided', () => {
      createComponent();

      expect(findTooltipUsername().text()).toBe('@johndoe');
    });

    it('does not render username when not provided', () => {
      createComponent({
        avatar: {
          name: 'Jane Doe',
          webUrl: 'https://gitlab.com/janedoe',
          avatarUrl: 'https://gitlab.com/uploads/user/avatar/456/avatar.png',
        },
      });

      expect(findTooltipUsername().exists()).toBe(false);
    });

    it('renders label when provided', () => {
      createComponent({ label: 'Assignee' });

      expect(findTooltipLabel().text()).toBe('Assignee');
    });

    it('does not render label when not provided', () => {
      createComponent();

      expect(findTooltipLabel().exists()).toBe(false);
    });
  });
});
