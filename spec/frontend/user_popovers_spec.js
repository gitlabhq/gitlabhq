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

  const dummyUser = { name: 'root' };
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
});
