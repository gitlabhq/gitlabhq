import Vue from 'vue';

import { sanitize } from '~/lib/dompurify';

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
          bioHtml: sanitize(userData.bio_html),
          workInformation: userData.work_information,
          websiteUrl: userData.website_url,
          pronouns: userData.pronouns,
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

const initializedPopovers = new Map();
let domObservedForChanges = false;

const addPopoversToModifiedTree = new MutationObserver(() => {
  const userLinks = document?.querySelectorAll('.js-user-link, .gfm-project_member');

  if (userLinks) {
    addPopovers(userLinks); /* eslint-disable-line no-use-before-define */
  }
});

function observeBody() {
  if (!domObservedForChanges) {
    addPopoversToModifiedTree.observe(document.body, {
      subtree: true,
      childList: true,
    });

    domObservedForChanges = true;
  }
}

export default function addPopovers(elements = document.querySelectorAll('.js-user-link')) {
  const userLinks = Array.from(elements);
  const UserPopoverComponent = Vue.extend(UserPopover);

  observeBody();

  return userLinks
    .filter(({ dataset }) => dataset.user || dataset.userId)
    .map((el) => {
      if (initializedPopovers.has(el)) {
        return initializedPopovers.get(el);
      }

      const user = {
        location: null,
        bio: null,
        workInformation: null,
        status: null,
        loaded: false,
      };
      const renderedPopover = new UserPopoverComponent({
        propsData: {
          target: el,
          user,
        },
      });

      initializedPopovers.set(el, renderedPopover);

      renderedPopover.$mount();

      el.addEventListener('mouseenter', ({ target }) => {
        removeTitle(target);
        const preloadedUserInfo = getPreloadedUserInfo(target.dataset);

        Object.assign(user, preloadedUserInfo);

        if (preloadedUserInfo.userId) {
          populateUserInfo(user);
        }
      });
      el.addEventListener('mouseleave', ({ target }) => {
        target.removeAttribute('aria-describedby');
      });

      return renderedPopover;
    });
}
