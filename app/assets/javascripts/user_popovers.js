import Vue, { ref } from 'vue';
import { debounce } from 'lodash';
import UsersCache from './lib/utils/users_cache';
import UserPopover from './vue_shared/components/user_popover/user_popover.vue';
import { USER_POPOVER_DELAY } from './vue_shared/components/user_popover/constants';

const removeTitle = (el) => {
  // Removing titles so its not showing tooltips also

  el.dataset.originalTitle = '';
  el.setAttribute('title', '');
};

const getPreloadedUserInfo = (dataset) => {
  const userId = dataset.user || dataset.userId;
  const { username, name, avatarUrl, email } = dataset;

  return {
    userId,
    username,
    name,
    avatarUrl,
    email,
  };
};

/**
 * Adds a UserPopover component to the body, hands over as much data as the target element has in data attributes.
 * loads based on data-user-id more data about a user from the API and sets it on the popover
 */
const populateUserInfo = (userRef) => {
  const { userId } = userRef.value;

  return Promise.all([UsersCache.retrieveById(userId), UsersCache.retrieveStatusById(userId)]).then(
    ([userData, status]) => {
      if (userData) {
        // eslint-disable-next-line no-param-reassign
        userRef.value = {
          ...userRef.value,
          id: userId,
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
          isFollowed: userData.is_followed,
          state: userData.state,
          loaded: true,
        };
      }

      if (status) {
        // eslint-disable-next-line no-param-reassign
        userRef.value.status = status;
      }

      return userRef.value;
    },
  );
};

function createPopover(el, userRef) {
  removeTitle(el);
  const preloadedUserInfo = getPreloadedUserInfo(el.dataset);

  Object.assign(userRef.value, preloadedUserInfo);

  if (preloadedUserInfo.userId) {
    populateUserInfo(userRef);
  }

  return new Vue({
    name: 'UserPopoverRoot',
    render(createElement) {
      return createElement(UserPopover, {
        props: {
          target: el,
          user: userRef.value,
          show: true,
          placement: el.dataset.placement || 'top',
          container: el.parentNode?.id || null,
        },
        on: {
          follow: () => {
            UsersCache.updateById(preloadedUserInfo.userId, { is_followed: true });
            // eslint-disable-next-line no-param-reassign
            userRef.value.isFollowed = true;
          },
          unfollow: () => {
            UsersCache.updateById(preloadedUserInfo.userId, { is_followed: false });
            // eslint-disable-next-line no-param-reassign
            userRef.value.isFollowed = false;
          },
        },
      });
    },
  });
}

function launchPopover(el, mountPopover) {
  if (el.user) return;

  const emptyUser = {
    location: null,
    bio: null,
    workInformation: null,
    status: null,
    isFollowed: false,
    loaded: false,
  };
  el.user = emptyUser;
  el.addEventListener(
    'mouseleave',
    ({ target }) => {
      target.removeAttribute('aria-describedby');
    },
    { once: true },
  );
  el.addEventListener(
    'focusout',
    ({ target }) => {
      target.removeAttribute('aria-describedby');
    },
    { once: true },
  );
  const popoverInstance = createPopover(el, ref(emptyUser));

  mountPopover(popoverInstance);
}

const userPopoverSelector =
  'a.js-user-link[data-user], a.js-user-link[data-user-id], .js-user-popover';

const getUserPopoverNode = (node) => node.closest(userPopoverSelector);

const lazyLaunchPopover = debounce((mountPopover, event) => {
  const userPopover = getUserPopoverNode(event.target);
  if (userPopover) {
    launchPopover(userPopover, mountPopover);
  }
}, USER_POPOVER_DELAY);

let hasAddedLazyPopovers = false;

export default function addPopovers(mountPopover = (instance) => instance.$mount()) {
  // The web request fails for anonymous users so we don't want to show the popover when the user is not signed in.
  // https://gitlab.com/gitlab-org/gitlab/-/issues/351395#note_1039341458
  if (window.gon?.current_user_id && !hasAddedLazyPopovers) {
    document.addEventListener('mouseover', (event) => lazyLaunchPopover(mountPopover, event));
    document.addEventListener('focusin', (event) => lazyLaunchPopover(mountPopover, event));
    hasAddedLazyPopovers = true;
  }
}
