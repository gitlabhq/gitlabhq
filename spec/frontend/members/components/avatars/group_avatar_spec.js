import { GlAvatarLabeled, GlAvatarLink } from '@gitlab/ui';
import { getByText as getByTextHelper } from '@testing-library/dom';
import { mount, createWrapper } from '@vue/test-utils';
import GroupAvatar from '~/members/components/avatars/group_avatar.vue';
import PrivateIcon from '~/members/components/icons/private_icon.vue';
import { group as member, privateGroup as privateMember } from '../../mock_data';

describe('MemberList', () => {
  let wrapper;

  const group = member.sharedWithGroup;

  const createComponent = (propsData = {}) => {
    wrapper = mount(GroupAvatar, {
      propsData: {
        member,
        ...propsData,
      },
    });
  };

  const getByText = (text, options) =>
    createWrapper(getByTextHelper(wrapper.element, text, options));

  it('renders link to group', () => {
    createComponent();

    const link = wrapper.findComponent(GlAvatarLink);

    expect(link.exists()).toBe(true);
    expect(link.attributes('href')).toBe(group.webUrl);
  });

  it("renders group's full name", () => {
    createComponent();

    expect(getByText(group.fullName).exists()).toBe(true);
  });

  it("renders group's avatar", () => {
    createComponent();

    expect(wrapper.findComponent(GlAvatarLabeled).attributes('src')).toBe(group.avatarUrl);
  });

  describe('when group is private', () => {
    beforeEach(() => {
      createComponent({ member: privateMember });
    });

    it('renders private avatar with icon', () => {
      expect(wrapper.findComponent(GlAvatarLink).exists()).toBe(false);
      expect(wrapper.findComponent(GlAvatarLabeled).props('label')).toBe('Private');
      expect(wrapper.findComponent(PrivateIcon).exists()).toBe(true);
    });
  });
});
