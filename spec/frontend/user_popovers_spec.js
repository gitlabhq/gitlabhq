import { within } from '@testing-library/dom';
import htmlMergeRequestWithMentions from 'test_fixtures/merge_requests/merge_request_with_mentions.html';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import UsersCache from '~/lib/utils/users_cache';
import initUserPopovers from '~/user_popovers';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/api/user_api', () => ({
  followUser: jest.fn().mockResolvedValue({}),
  unfollowUser: jest.fn().mockResolvedValue({}),
}));

describe('User Popovers', () => {
  const selector = '.js-user-link[data-user], .js-user-link[data-user-id]';
  const findFixtureLinks = () => Array.from(document.querySelectorAll(selector));
  const createUserLink = () => {
    const link = document.createElement('a');

    link.classList.add('js-user-link');
    link.dataset.user = '1';

    return link;
  };
  const findPopovers = () => {
    return Array.from(document.querySelectorAll('[data-testid="user-popover"]'));
  };

  const dummyUser = { name: 'root', username: 'root', is_followed: false };
  const dummyUserStatus = { message: 'active' };

  const triggerEvent = (eventName, el) => {
    const event = new MouseEvent(eventName, {
      bubbles: true,
      cancelable: true,
      view: window,
    });

    el.dispatchEvent(event);
  };

  const setupTestSubject = () => {
    setHTMLFixture(htmlMergeRequestWithMentions);

    const usersCacheSpy = () => Promise.resolve(dummyUser);
    jest.spyOn(UsersCache, 'retrieveById').mockImplementation((userId) => usersCacheSpy(userId));

    const userStatusCacheSpy = () => Promise.resolve(dummyUserStatus);
    jest
      .spyOn(UsersCache, 'retrieveStatusById')
      .mockImplementation((userId) => userStatusCacheSpy(userId));
    jest.spyOn(UsersCache, 'updateById');

    initUserPopovers((popoverInstance) => {
      const mountingRoot = document.createElement('div');
      document.body.appendChild(mountingRoot);
      popoverInstance.$mount(mountingRoot);
    });
  };

  describe('when signed out', () => {
    beforeEach(() => {
      setupTestSubject();
    });

    it('does not show a placeholder popover on hover', () => {
      const linksWithUsers = findFixtureLinks();
      linksWithUsers.forEach((el) => {
        triggerEvent('mouseover', el);
      });

      expect(findPopovers()).toHaveLength(0);
    });
  });

  describe('when signed in', () => {
    beforeEach(() => {
      window.gon.current_user_id = 7;

      setupTestSubject();
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    describe.each(['mouseover', 'focusin'])('shows a placeholder popover on %s', (eventType) => {
      let linksWithUsers;

      beforeEach(() => {
        linksWithUsers = findFixtureLinks();
        linksWithUsers.forEach((el) => {
          triggerEvent(eventType, el);
        });
      });

      it('for initial links', () => {
        expect(findPopovers()).toHaveLength(linksWithUsers.length);
      });

      it('for elements added after initial load', () => {
        const addedLinks = [createUserLink(), createUserLink()];
        addedLinks.forEach((link) => {
          document.body.appendChild(link);
        });

        jest.runOnlyPendingTimers();

        addedLinks.forEach((link) => {
          triggerEvent(eventType, link);
        });

        expect(findPopovers()).toHaveLength(linksWithUsers.length + addedLinks.length);
      });

      it('for non-link elements', () => {
        const div = document.createElement('div');
        div.classList.add('js-user-popover');
        div.dataset.user = '1';
        document.body.appendChild(div);

        jest.runOnlyPendingTimers();

        expect(findPopovers()).toHaveLength(linksWithUsers.length);

        triggerEvent(eventType, div);

        expect(findPopovers()).toHaveLength(linksWithUsers.length + 1);
      });
    });

    it('does not initialize the popovers for group references', () => {
      const [groupLink] = Array.from(document.querySelectorAll('.js-user-link[data-group]'));

      triggerEvent('mouseover', groupLink);
      jest.runOnlyPendingTimers();

      expect(findPopovers()).toHaveLength(0);
    });

    // TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/18442
    // Remove as @all is deprecated.
    it('does not initialize the popovers for @all references', () => {
      const [projectLink] = Array.from(document.querySelectorAll('.js-user-link[data-project]'));

      triggerEvent('mouseover', projectLink);
      jest.runOnlyPendingTimers();

      expect(findPopovers()).toHaveLength(0);
    });

    it('does not initialize the user popovers twice for the same element', () => {
      const [firstUserLink] = findFixtureLinks();

      const events = ['mouseover', 'mouseleave', 'mouseover', 'focusin', 'focusout'];

      events.forEach((event) => {
        triggerEvent(event, firstUserLink);
        jest.runOnlyPendingTimers();
      });

      expect(findPopovers()).toHaveLength(1);
    });

    describe.each(['focusin', 'mouseover'])(
      'when user link emits %s event with empty user cache',
      (eventType) => {
        let userLink;

        beforeEach(() => {
          UsersCache.retrieveById.mockReset();

          [userLink] = findFixtureLinks();

          triggerEvent(eventType, userLink);
        });

        it('populates popover with preloaded user data', () => {
          const { name, userId, username, email } = userLink.dataset;

          expect(userLink.user).toEqual(
            expect.objectContaining({
              name,
              userId,
              username,
              email,
            }),
          );
        });
      },
    );

    describe.each([
      { eventType: 'mouseover', leaveEvent: 'mouseleave' },
      { eventType: 'focusin', leaveEvent: 'focusout' },
    ])('when user link emits $eventType event', ({ eventType, leaveEvent }) => {
      let userLink;

      beforeEach(() => {
        [userLink] = findFixtureLinks();

        triggerEvent(eventType, userLink);
      });

      it('removes title attribute from user links', () => {
        expect(userLink.getAttribute('title')).toBe('');
        expect(userLink.dataset.originalTitle).toBe('');
      });

      it('fetches user info and status from the user cache', () => {
        const { userId } = userLink.dataset;

        expect(UsersCache.retrieveById).toHaveBeenCalledWith(userId);
        expect(UsersCache.retrieveStatusById).toHaveBeenCalledWith(userId);
      });

      it(`removes aria-describedby attribute from the user link on ${leaveEvent}`, () => {
        userLink.setAttribute('aria-describedby', 'popover');
        triggerEvent(leaveEvent, userLink);

        expect(userLink.getAttribute('aria-describedby')).toBe(null);
      });

      it('updates toggle follow button and `UsersCache` when toggle follow button is clicked', async () => {
        const [firstPopover] = findPopovers();
        const withinFirstPopover = within(firstPopover);
        const findFollowButton = () => withinFirstPopover.queryByRole('button', { name: 'Follow' });
        const findUnfollowButton = () =>
          withinFirstPopover.queryByRole('button', { name: 'Unfollow' });

        jest.runOnlyPendingTimers();

        const { userId } = document.querySelector(selector).dataset;

        triggerEvent('click', findFollowButton());

        await waitForPromises();

        expect(findUnfollowButton()).not.toBe(null);
        expect(UsersCache.updateById).toHaveBeenCalledWith(userId, { is_followed: true });

        triggerEvent('click', findUnfollowButton());

        await waitForPromises();

        expect(findFollowButton()).not.toBe(null);
        expect(UsersCache.updateById).toHaveBeenCalledWith(userId, { is_followed: false });
      });
    });
  });
});
