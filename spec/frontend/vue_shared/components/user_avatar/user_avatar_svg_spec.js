import { shallowMount } from '@vue/test-utils';
import UserAvatarSvg from '~/vue_shared/components/user_avatar/user_avatar_svg.vue';

describe('User Avatar Svg Component', () => {
  describe('Initialization', () => {
    let wrapper;

    beforeEach(() => {
      wrapper = shallowMount(UserAvatarSvg, {
        propsData: {
          size: 99,
          svg:
            '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16"><path d="M1.707 15.707C1.077z"/></svg>',
        },
      });
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('should have <svg> as a child element', () => {
      expect(wrapper.element.tagName).toEqual('svg');
      expect(wrapper.html()).toContain('<path');
    });
  });
});
