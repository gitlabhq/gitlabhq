import { GlAvatarLink } from '@gitlab/ui';
import { getByText as getByTextHelper } from '@testing-library/dom';
import { mount, createWrapper } from '@vue/test-utils';
import GroupAvatar from '~/members/components/avatars/group_avatar.vue';
import { group as member } from '../../mock_data';

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

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders link to group', () => {
    const link = wrapper.find(GlAvatarLink);

    expect(link.exists()).toBe(true);
    expect(link.attributes('href')).toBe(group.webUrl);
  });

  it("renders group's full name", () => {
    expect(getByText(group.fullName).exists()).toBe(true);
  });

  it("renders group's avatar", () => {
    expect(wrapper.find('img').attributes('src')).toBe(group.avatarUrl);
  });
});
