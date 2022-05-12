import { within } from '@testing-library/dom';

import UsersCache from '~/lib/utils/users_cache';
import initUserPopovers from '~/user_popovers';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/api/user_api', () => ({
  followUser: jest.fn().mockResolvedValue({}),
  unfollowUser: jest.fn().mockResolvedValue({}),
}));

describe('User Popovers', () => {
  const fixtureTemplate = 'merge_requests/merge_request_with_mentions.html';

  const selector = '.js-user-link, .gfm-project_member';
  const findFixtureLinks = () => {
    return Array.from(document.querySelectorAll(selector)).filter(
      ({ dataset }) => dataset.user || dataset.userId,
    );
  };
  const createUserLink = () => {
    const link = document.createElement('a');

    link.classList.add('js-user-link');
    link.setAttribute('data-user', '1');

    return link;
  };

  const dummyUser = { name: 'root', username: 'root', is_followed: false };
  const dummyUserStatus = { message: 'active' };

  let popovers;

  const triggerEvent = (eventName, el) => {
    const event = new MouseEvent(eventName, {
      bubbles: true,
      cancelable: true,
      view: window,
    });

    el.dispatchEvent(event);
  };

  beforeEach(() => {
    loadFixtures(fixtureTemplate);

    const usersCacheSpy = () => Promise.resolve(dummyUser);
    jest.spyOn(UsersCache, 'retrieveById').mockImplementation((userId) => usersCacheSpy(userId));

    const userStatusCacheSpy = () => Promise.resolve(dummyUserStatus);
    jest
      .spyOn(UsersCache, 'retrieveStatusById')
      .mockImplementation((userId) => userStatusCacheSpy(userId));
    jest.spyOn(UsersCache, 'updateById');

    popovers = initUserPopovers(document.querySelectorAll(selector));
  });

  it('initializes a popover for each user link with a user id', () => {
    const linksWithUsers = findFixtureLinks();

    expect(linksWithUsers.length).toBe(popovers.length);
  });

  it('adds popovers to user links added to the DOM tree after the initial call', async () => {
    document.body.appendChild(createUserLink());
    document.body.appendChild(createUserLink());

    const linksWithUsers = findFixtureLinks();

    expect(linksWithUsers.length).toBe(popovers.length + 2);
  });

  it('does not initialize the user popovers twice for the same element', () => {
    const newPopovers = initUserPopovers(document.querySelectorAll(selector));
    const samePopovers = popovers.every((popover, index) => newPopovers[index] === popover);

    expect(samePopovers).toBe(true);
  });

  describe('when user link emits mouseenter event', () => {
    let userLink;

    beforeEach(() => {
      UsersCache.retrieveById.mockReset();

      userLink = document.querySelector(selector);

      triggerEvent('mouseenter', userLink);
    });

    it('removes title attribute from user links', () => {
      expect(userLink.getAttribute('title')).toBeFalsy();
      expect(userLink.dataset.originalTitle).toBeFalsy();
    });

    it('populates popovers with preloaded user data', () => {
      const { name, userId, username } = userLink.dataset;
      const [firstPopover] = popovers;

      expect(firstPopover.$props.user).toEqual(
        expect.objectContaining({
          name,
          userId,
          username,
        }),
      );
    });

    it('fetches user info and status from the user cache', () => {
      const { userId } = userLink.dataset;

      expect(UsersCache.retrieveById).toHaveBeenCalledWith(userId);
      expect(UsersCache.retrieveStatusById).toHaveBeenCalledWith(userId);
    });
  });

  it('removes aria-describedby attribute from the user link on mouseleave', () => {
    const userLink = document.querySelector(selector);

    userLink.setAttribute('aria-describedby', 'popover');
    triggerEvent('mouseleave', userLink);

    expect(userLink.getAttribute('aria-describedby')).toBe(null);
  });

  it('updates toggle follow button and `UsersCache` when toggle follow button is clicked', async () => {
    const [firstPopover] = popovers;
    const withinFirstPopover = within(firstPopover.$el);
    const findFollowButton = () => withinFirstPopover.queryByRole('button', { name: 'Follow' });
    const findUnfollowButton = () => withinFirstPopover.queryByRole('button', { name: 'Unfollow' });

    const userLink = document.querySelector(selector);
    triggerEvent('mouseenter', userLink);

    await waitForPromises();

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
