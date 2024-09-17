import { GlAvatarLabeled, GlBadge, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import AdminUserAvatar from '~/vue_shared/components/users_table/user_avatar.vue';
import { LENGTH_OF_USER_NOTE_TOOLTIP } from '~/vue_shared/components/users_table/constants';
import { truncate } from '~/lib/utils/text_utility';
import { MOCK_USERS, MOCK_ADMIN_USER_PATH } from './mock_data';

describe('AdminUserAvatar component', () => {
  let wrapper;
  const user = MOCK_USERS[0];

  const findNote = () => wrapper.findComponent(GlIcon);
  const findAvatar = () => wrapper.findComponent(GlAvatarLabeled);
  const findUserLink = () => wrapper.find('.js-user-popover');
  const findAllBadges = () => wrapper.findAllComponents(GlBadge);
  const findTooltip = () => getBinding(findNote().element, 'gl-tooltip');

  const initComponent = (props = {}) => {
    wrapper = shallowMount(AdminUserAvatar, {
      propsData: {
        user,
        adminUserPath: MOCK_ADMIN_USER_PATH,
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      stubs: {
        GlAvatarLabeled,
      },
    });
  };

  describe('when initialized', () => {
    beforeEach(() => {
      initComponent();
    });

    it('adds a user link hover card', () => {
      expect(findUserLink().attributes()).toMatchObject({
        'data-user-id': user.id.toString(),
        'data-username': user.username,
      });
    });

    it("renders the user's name with an admin path link", () => {
      const avatar = findAvatar();

      expect(avatar.props('label')).toBe(user.name);
      expect(avatar.props('labelLink')).toBe(MOCK_ADMIN_USER_PATH.replace('id', user.username));
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

  describe('when user has an email address', () => {
    beforeEach(() => {
      initComponent();
    });

    it("renders the user's email with a mailto link", () => {
      const avatar = findAvatar();

      expect(avatar.props('subLabel')).toBe(user.email);
      expect(avatar.props('subLabelLink')).toBe(`mailto:${user.email}`);
    });
  });

  describe('when user does not have an email address', () => {
    beforeEach(() => {
      initComponent({ user: { ...MOCK_USERS[0], email: null } });
    });

    it("renders the user's username without a link", () => {
      const avatar = findAvatar();

      expect(avatar.props('subLabel')).toBe(`@${user.username}`);
      expect(avatar.props('subLabelLink')).toBe('');
    });
  });

  describe('when user id is a graphql id', () => {
    const id = '123';

    beforeEach(() => {
      initComponent({ user: { ...user, id: `gid://gitlab/User/${id}` } });
    });

    it('converts the gid to normal id and renders the popover', () => {
      expect(findUserLink().attributes()).toMatchObject({
        'data-user-id': id,
        'data-username': user.username,
      });
    });
  });
});
