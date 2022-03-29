import UsersCache from '~/lib/utils/users_cache';
import initUserPopovers from '~/user_popovers';

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
  const findPopovers = () => {
    return Array.from(document.querySelectorAll('[data-testid="user-popover"]'));
  };

  const dummyUser = { name: 'root' };
  const dummyUserStatus = { message: 'active' };

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

    initUserPopovers(document.querySelectorAll(selector), (popoverInstance) => {
      const mountingRoot = document.createElement('div');
      document.body.appendChild(mountingRoot);
      popoverInstance.$mount(mountingRoot);
    });
  });

  describe('shows a placeholder popover on hover', () => {
    let linksWithUsers;
    beforeEach(() => {
      linksWithUsers = findFixtureLinks();
      linksWithUsers.forEach((el) => {
        triggerEvent('mouseenter', el);
      });
    });

    it('for initial links', () => {
      expect(findPopovers().length).toBe(linksWithUsers.length);
    });

    it('for elements added after initial load', async () => {
      const addedLinks = [createUserLink(), createUserLink()];
      addedLinks.forEach((link) => {
        document.body.appendChild(link);
      });

      await Promise.resolve();

      addedLinks.forEach((link) => {
        triggerEvent('mouseenter', link);
      });

      expect(findPopovers().length).toBe(linksWithUsers.length + addedLinks.length);
    });
  });

  it('does not initialize the user popovers twice for the same element', () => {
    const [firstUserLink] = findFixtureLinks();
    triggerEvent('mouseenter', firstUserLink);
    triggerEvent('mouseleave', firstUserLink);
    triggerEvent('mouseenter', firstUserLink);

    expect(findPopovers().length).toBe(1);
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

    it('populates popover with preloaded user data', () => {
      const { name, userId, username } = userLink.dataset;
      const [firstPopover] = findFixtureLinks();

      expect(firstPopover.user).toEqual(
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
});
