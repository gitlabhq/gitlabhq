import { GlAvatarLink, GlAvatarLabeled, GlBadge } from '@gitlab/ui';
import { mount } from '@vue/test-utils';

import AdminUserAvatar from '~/admin/users/components/user_avatar.vue';
import { users, paths } from '../mock_data';

describe('AdminUserAvatar component', () => {
  let wrapper;
  const user = users[0];
  const adminUserPath = paths.adminUser;

  const findAvatar = () => wrapper.find(GlAvatarLabeled);
  const findAvatarLink = () => wrapper.find(GlAvatarLink);
  const findAllBadges = () => wrapper.findAll(GlBadge);

  const initComponent = (props = {}) => {
    wrapper = mount(AdminUserAvatar, {
      propsData: {
        user,
        adminUserPath,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when initialized', () => {
    beforeEach(() => {
      initComponent();
    });

    it("links to the user's admin path", () => {
      expect(findAvatarLink().attributes()).toMatchObject({
        href: adminUserPath.replace('id', user.username),
        'data-user-id': user.id.toString(),
        'data-username': user.username,
      });
    });

    it("renders the user's name", () => {
      expect(findAvatar().props('label')).toBe(user.name);
    });

    it("renders the user's email", () => {
      expect(findAvatar().props('subLabel')).toBe(user.email);
    });

    it("renders the user's avatar image", () => {
      expect(findAvatar().attributes('src')).toBe(user.avatarUrl);
    });

    it("renders the user's badges", () => {
      findAllBadges().wrappers.forEach((badge, idx) => {
        expect(badge.text()).toBe(user.badges[idx].text);
        expect(badge.props('variant')).toBe(user.badges[idx].variant);
      });
    });
  });
});
