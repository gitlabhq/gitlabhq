import { getByText as getByTextHelper } from '@testing-library/dom';
import { mount, createWrapper } from '@vue/test-utils';
import InviteAvatar from '~/members/components/avatars/invite_avatar.vue';
import { invite as member } from '../../mock_data';

describe('MemberList', () => {
  let wrapper;

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

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders email as name', () => {
    expect(getByText(invite.email).exists()).toBe(true);
  });

  it('renders avatar', () => {
    expect(wrapper.find('img').attributes('src')).toBe(invite.avatarUrl);
  });
});
