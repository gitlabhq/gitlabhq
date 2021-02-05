import { GlAvatarLink, GlAvatarLabeled, GlBadge, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import AdminUserAvatar from '~/admin/users/components/user_avatar.vue';
import { LENGTH_OF_USER_NOTE_TOOLTIP } from '~/admin/users/constants';
import { truncate } from '~/lib/utils/text_utility';
import { users, paths } from '../mock_data';

describe('AdminUserAvatar component', () => {
  let wrapper;
  const user = users[0];
  const adminUserPath = paths.adminUser;

  const findNote = () => wrapper.find(GlIcon);
  const findAvatar = () => wrapper.find(GlAvatarLabeled);
  const findAvatarLink = () => wrapper.find(GlAvatarLink);
  const findAllBadges = () => wrapper.findAll(GlBadge);
  const findTooltip = () => getBinding(findNote().element, 'gl-tooltip');

  const initComponent = (props = {}) => {
    wrapper = shallowMount(AdminUserAvatar, {
      propsData: {
        user,
        adminUserPath,
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective(),
      },
      stubs: {
        GlAvatarLabeled,
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

    it('renders a user note icon', () => {
      expect(findNote().exists()).toBe(true);
      expect(findNote().props('name')).toBe('document');
    });

    it("renders the user's note tooltip", () => {
      const tooltip = findTooltip();

      expect(tooltip).toBeDefined();
      expect(tooltip.value).toBe(user.note);
    });

    it("renders the user's badges", () => {
      findAllBadges().wrappers.forEach((badge, idx) => {
        expect(badge.text()).toBe(user.badges[idx].text);
        expect(badge.props('variant')).toBe(user.badges[idx].variant);
      });
    });

    describe('and the user note is very long', () => {
      const noteText = new Array(LENGTH_OF_USER_NOTE_TOOLTIP + 1).join('a');

      beforeEach(() => {
        initComponent({
          user: {
            ...user,
            note: noteText,
          },
        });
      });

      it("renders a truncated user's note tooltip", () => {
        const tooltip = findTooltip();

        expect(tooltip).toBeDefined();
        expect(tooltip.value).toBe(truncate(noteText, LENGTH_OF_USER_NOTE_TOOLTIP));
      });
    });

    describe('and the user does not have a note', () => {
      beforeEach(() => {
        initComponent({
          user: {
            ...user,
            note: null,
          },
        });
      });

      it('does not render a user note', () => {
        expect(findNote().exists()).toBe(false);
      });
    });
  });
});
