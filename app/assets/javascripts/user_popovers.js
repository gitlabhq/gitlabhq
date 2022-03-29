import Vue from 'vue';
import UsersCache from './lib/utils/users_cache';
import UserPopover from './vue_shared/components/user_popover/user_popover.vue';

const removeTitle = (el) => {
  // Removing titles so its not showing tooltips also

  el.dataset.originalTitle = '';
  el.setAttribute('title', '');
};

const getPreloadedUserInfo = (dataset) => {
  const userId = dataset.user || dataset.userId;
  const { username, name, avatarUrl } = dataset;

  return {
    userId,
    username,
    name,
    avatarUrl,
  };
};

/**
 * Adds a UserPopover component to the body, hands over as much data as the target element has in data attributes.
 * loads based on data-user-id more data about a user from the API and sets it on the popover
 */
const populateUserInfo = (user) => {
  const { userId } = user;

  return Promise.all([UsersCache.retrieveById(userId), UsersCache.retrieveStatusById(userId)]).then(
    ([userData, status]) => {
      if (userData) {
        Object.assign(user, {
          avatarUrl: userData.avatar_url,
          bot: userData.bot,
          username: userData.username,
          name: userData.name,
          location: userData.location,
          bio: userData.bio,
          workInformation: userData.work_information,
          websiteUrl: userData.website_url,
          pronouns: userData.pronouns,
          localTime: userData.local_time,
          loaded: true,
        });
      }

      if (status) {
        Object.assign(user, {
          status,
        });
      }

      return user;
    },
  );
};

function initPopover(el, user, mountPopover) {
  const preloadedUserInfo = getPreloadedUserInfo(el.dataset);

  Object.assign(user, preloadedUserInfo);

  if (preloadedUserInfo.userId) {
    populateUserInfo(user);
  }
  const UserPopoverComponent = Vue.extend(UserPopover);
  const popoverInstance = new UserPopoverComponent({
    propsData: {
      target: el,
      user,
    },
  });
  mountPopover(popoverInstance);
  // wait for component to actually mount
  setTimeout(() => {
    // trigger an event to force tooltip to show
    const event = new MouseEvent('mouseenter');
    event.isSelfTriggered = true;
    el.dispatchEvent(event);
  });
}

function initPopovers(userLinks, mountPopover) {
  userLinks
    .filter(({ dataset, user }) => !user && (dataset.user || dataset.userId))
    .forEach((el) => {
      const user = {
        location: null,
        bio: null,
        workInformation: null,
        status: null,
        loaded: false,
      };
      el.user = user;
      const init = initPopover.bind(null, el, user, mountPopover);
      el.addEventListener('mouseenter', init, { once: true });
      el.addEventListener('mouseenter', ({ target, isSelfTriggered }) => {
        if (!isSelfTriggered) return;
        removeTitle(target);
      });
      el.addEventListener('mouseleave', ({ target }) => {
        target.removeAttribute('aria-describedby');
      });
    });
}

const userLinkSelector = 'a.js-user-link, a.gfm-project_member';

const getUserLinkNodes = (node) => {
  if (!('matches' in node)) return null;
  if (node.matches(userLinkSelector)) return [node];
  return Array.from(node.querySelectorAll(userLinkSelector));
};

let observer;

export default function addPopovers(
  elements = document.querySelectorAll('.js-user-link'),
  mountPopover = (popoverInstance) => popoverInstance.$mount(),
) {
  const userLinks = Array.from(elements);

  initPopovers(userLinks, mountPopover);

  if (!observer) {
    observer = new MutationObserver((mutationsList) => {
      const newUserLinks = mutationsList
        .filter((mutation) => mutation.type === 'childList' && mutation.addedNodes)
        .reduce((acc, mutation) => {
          const userLinkNodes = Array.from(mutation.addedNodes)
            .flatMap(getUserLinkNodes)
            .filter(Boolean);
          acc.push(...userLinkNodes);
          return acc;
        }, []);

      if (newUserLinks.length !== 0) {
        initPopovers(newUserLinks, mountPopover);
      }
    });
    observer.observe(document.body, {
      subtree: true,
      childList: true,
    });

    document.addEventListener('beforeunload', () => {
      observer.disconnect();
    });
  }
}
