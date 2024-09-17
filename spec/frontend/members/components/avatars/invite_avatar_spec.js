import { getByText as getByTextHelper } from '@testing-library/dom';
import { mount, createWrapper } from '@vue/test-utils';
import { GlAvatarLabeled } from '@gitlab/ui';
import InviteAvatar from '~/members/components/avatars/invite_avatar.vue';
import { invite as member } from '../../mock_data';

describe('MemberList', () => {
  let wrapper;

  const findAvatarLabeled = () => wrapper.findComponent(GlAvatarLabeled);

  const { invite } = member;

  const createComponent = (propsData = {}) => {
    wrapper = mount(InviteAvatar, {
      propsData: {
        member,
        ...propsData,
      },
    });
  };

  const getByText = (text, options) =>
    createWrapper(getByTextHelper(wrapper.element, text, options));

  beforeEach(() => {
    createComponent();
  });

  it('renders email as name', () => {
    expect(getByText(invite.email).exists()).toBe(true);
  });

  it('renders avatar', () => {
    expect(findAvatarLabeled().attributes('src')).toBe(invite.avatarUrl);
  });
});
