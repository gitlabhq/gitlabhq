import { GlAvatar } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContextSwitcherToggle from '~/super_sidebar/components/context_switcher_toggle.vue';

describe('ContextSwitcherToggle component', () => {
  let wrapper;

  const context = {
    id: 1,
    title: 'Title',
    avatar: '/path/to/avatar.png',
  };

  const findGlAvatar = () => wrapper.getComponent(GlAvatar);

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(ContextSwitcherToggle, {
      propsData: {
        context,
        expanded: false,
        ...props,
      },
    });
  };

  describe('with an avatar', () => {
    it('passes the correct props to GlAvatar', () => {
      createWrapper();
      const avatar = findGlAvatar();

      expect(avatar.props('shape')).toBe('rect');
      expect(avatar.props('entityName')).toBe(context.title);
      expect(avatar.props('entityId')).toBe(context.id);
      expect(avatar.props('src')).toBe(context.avatar);
    });

    it('renders the avatar with a custom shape', () => {
      const customShape = 'circle';
      createWrapper({
        context: {
          ...context,
          avatar_shape: customShape,
        },
      });
      const avatar = findGlAvatar();

      expect(avatar.props('shape')).toBe(customShape);
    });
  });
});
