import { GlAvatarLink, GlAvatarLabeled, GlBadge } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import UserAvatar from '~/members/components/avatars/user_avatar.vue';
import { AVAILABILITY_STATUS } from '~/set_status_modal/constants';

import { member as memberMock, member2faEnabled, orphanedMember } from '../../mock_data';

describe('UserAvatar', () => {
  let wrapper;

  const findAvatarLabeled = () => wrapper.findComponent(GlAvatarLabeled);

  const { user } = memberMock;

  const createComponent = (propsData = {}, provide = {}) => {
    wrapper = mountExtended(UserAvatar, {
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

  const findStatusEmoji = (emoji) => wrapper.find(`gl-emoji[data-name="${emoji}"]`);

  it("renders link to user's profile", () => {
    createComponent();

    const link = wrapper.findComponent(GlAvatarLink);

    expect(link.exists()).toBe(true);
    expect(link.attributes()).toMatchObject({
      href: user.webUrl,
      'data-user-id': `${user.id}`,
      'data-username': user.username,
      'data-email': user.email,
    });
  });

  it("renders user's name", () => {
    createComponent();

    expect(wrapper.findByText(user.name).exists()).toBe(true);
  });

  it("renders user's username", () => {
    createComponent();

    expect(wrapper.findByText(`@${user.username}`).exists()).toBe(true);
  });

  it("renders user's avatar", () => {
    createComponent();

    expect(findAvatarLabeled().attributes('src')).toBe(
      'https://www.gravatar.com/avatar/4816142ef496f956a277bedf1a40607b?s=80&d=identicon&width=96',
    );
  });
  it('does not render user avatar image if avatarUrl is null', () => {
    createComponent({
      member: {
        ...memberMock,
        user: {
          ...memberMock.user,
          avatarUrl: null,
        },
      },
    });
    expect(wrapper.find('img').exists()).toBe(false);
  });

  describe('when user property does not exist', () => {
    it('displays an orphaned user', () => {
      createComponent({ member: orphanedMember });

      expect(wrapper.findByText('Orphaned member').exists()).toBe(true);
    });
  });

  describe('badges', () => {
    it.each`
      member                                                            | badgeText
      ${{ ...memberMock, user: { ...memberMock.user, blocked: true } }} | ${'Blocked'}
      ${member2faEnabled}                                               | ${'2FA'}
    `('renders the "$badgeText" badge', ({ member, badgeText }) => {
      createComponent({ member });

      expect(wrapper.findComponent(GlBadge).text()).toBe(badgeText);
    });

    it('renders the "It\'s you" badge when member is current user', () => {
      createComponent({ isCurrentUser: true });

      expect(wrapper.findByText("It's you").exists()).toBe(true);
    });

    it('does not render 2FA badge when `canManageMembers` is `false`', () => {
      createComponent({ member: member2faEnabled }, { canManageMembers: false });

      expect(wrapper.findByText('2FA').exists()).toBe(false);
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

      describe('when `user.showStatus` is `false', () => {
        it('does not display status emoji', () => {
          createComponent({
            member: {
              ...memberMock,
              user: {
                ...memberMock.user,
                showStatus: false,
                status: { emoji, messageHtml: 'On vacation' },
              },
            },
          });

          expect(findStatusEmoji(emoji).exists()).toBe(false);
        });
      });
    });

    describe('when not set', () => {
      it('does not display status emoji', () => {
        createComponent();

        expect(findStatusEmoji(emoji).exists()).toBe(false);
      });
    });
  });

  describe('user availability', () => {
    describe('when `user.availability` is `null`', () => {
      it("does not show `(Busy)` next to user's name", () => {
        createComponent();

        expect(wrapper.findByText('(Busy)').exists()).toBe(false);
      });
    });

    describe(`when user.availability is ${AVAILABILITY_STATUS.BUSY}`, () => {
      it("shows `(Busy)` next to user's name", () => {
        createComponent({
          member: {
            ...memberMock,
            user: {
              ...memberMock.user,
              availability: AVAILABILITY_STATUS.BUSY,
            },
          },
        });

        expect(wrapper.findByText('(Busy)').exists()).toBe(true);
      });
    });
  });
});
