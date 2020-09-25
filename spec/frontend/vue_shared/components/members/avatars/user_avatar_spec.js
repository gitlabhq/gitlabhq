import { mount, createWrapper } from '@vue/test-utils';
import { getByText as getByTextHelper } from '@testing-library/dom';
import { GlAvatarLink } from '@gitlab/ui';
import { member, orphanedMember } from '../mock_data';
import UserAvatar from '~/vue_shared/components/members/avatars/user_avatar.vue';

describe('MemberList', () => {
  let wrapper;

  const { user } = member;

  const createComponent = (propsData = {}) => {
    wrapper = mount(UserAvatar, {
      propsData: {
        member,
        ...propsData,
      },
    });
  };

  const getByText = (text, options) =>
    createWrapper(getByTextHelper(wrapper.element, text, options));

  afterEach(() => {
    wrapper.destroy();
  });

  it("renders link to user's profile", () => {
    createComponent();

    const link = wrapper.find(GlAvatarLink);

    expect(link.exists()).toBe(true);
    expect(link.attributes()).toMatchObject({
      href: user.webUrl,
      'data-user-id': `${user.id}`,
      'data-username': user.username,
    });
  });

  it("renders user's name", () => {
    createComponent();

    expect(getByText(user.name).exists()).toBe(true);
  });

  it("renders user's username", () => {
    createComponent();

    expect(getByText(`@${user.username}`).exists()).toBe(true);
  });

  it("renders user's avatar", () => {
    createComponent();

    expect(wrapper.find('img').attributes('src')).toBe(user.avatarUrl);
  });

  describe('when user property does not exist', () => {
    it('displays an orphaned user', () => {
      createComponent({ member: orphanedMember });

      expect(getByText('Orphaned member').exists()).toBe(true);
    });
  });
});
