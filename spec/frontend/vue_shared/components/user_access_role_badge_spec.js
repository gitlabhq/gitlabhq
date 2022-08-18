import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import UserAccessRoleBadge from '~/vue_shared/components/user_access_role_badge.vue';

describe('UserAccessRoleBadge', () => {
  let wrapper;

  const createComponent = ({ slots } = {}) => {
    wrapper = shallowMount(UserAccessRoleBadge, {
      slots,
    });
  };

  it('renders slot content inside GlBadge', () => {
    createComponent({
      slots: {
        default: 'test slot content',
      },
    });

    const badge = wrapper.findComponent(GlBadge);

    expect(badge.exists()).toBe(true);
    expect(badge.html()).toContain('test slot content');
  });
});
