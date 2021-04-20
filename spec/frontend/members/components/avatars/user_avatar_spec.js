import { GlAvatarLink, GlBadge } from '@gitlab/ui';
import { within } from '@testing-library/dom';
import { mount, createWrapper } from '@vue/test-utils';
import UserAvatar from '~/members/components/avatars/user_avatar.vue';
import { member as memberMock, member2faEnabled, orphanedMember } from '../../mock_data';

describe('UserAvatar', () => {
  let wrapper;

  const { user } = memberMock;

  const createComponent = (propsData = {}, provide = {}) => {
    wrapper = mount(UserAvatar, {
      propsData: {
        member: memberMock,
        isCurrentUser: false,
        ...propsData,
      },
      provide: {
        canManageMembers: true,
        ...provide,
      },
    });
  };

  const getByText = (text, options) =>
    createWrapper(within(wrapper.element).findByText(text, options));

  const findStatusEmoji = (emoji) => wrapper.find(`gl-emoji[data-name="${emoji}"]`);

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

  describe('badges', () => {
    it.each`
      member                                                            | badgeText
      ${{ ...memberMock, user: { ...memberMock.user, blocked: true } }} | ${'Blocked'}
      ${member2faEnabled}                                               | ${'2FA'}
    `('renders the "$badgeText" badge', ({ member, badgeText }) => {
      createComponent({ member });

      expect(wrapper.find(GlBadge).text()).toBe(badgeText);
    });

    it('renders the "It\'s you" badge when member is current user', () => {
      createComponent({ isCurrentUser: true });

      expect(getByText("It's you").exists()).toBe(true);
    });

    it('does not render 2FA badge when `canManageMembers` is `false`', () => {
      createComponent({ member: member2faEnabled }, { canManageMembers: false });

      expect(within(wrapper.element).queryByText('2FA')).toBe(null);
    });
  });

  describe('user status', () => {
    const emoji = 'island';

    describe('when set', () => {
      it('displays the status emoji', () => {
        createComponent({
          member: {
            ...memberMock,
            user: {
              ...memberMock.user,
              status: { emoji, messageHtml: 'On vacation' },
            },
          },
        });

        expect(findStatusEmoji(emoji).exists()).toBe(true);
      });
    });

    describe('when not set', () => {
      it('does not display status emoji', () => {
        createComponent();

        expect(findStatusEmoji(emoji).exists()).toBe(false);
      });
    });
  });
});
