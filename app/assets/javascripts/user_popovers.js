import Vue from 'vue';
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
const populateUserInfo = (user) => {
  const { userId } = user;

  return Promise.all([UsersCache.retrieveById(userId), UsersCache.retrieveStatusById(userId)]).then(
    ([userData, status]) => {
      if (userData) {
        Object.assign(user, {
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

function createPopover(el, user) {
  removeTitle(el);
  const preloadedUserInfo = getPreloadedUserInfo(el.dataset);

  Object.assign(user, preloadedUserInfo);

  if (preloadedUserInfo.userId) {
    populateUserInfo(user);
  }
  const UserPopoverComponent = Vue.extend(UserPopover);

  return new UserPopoverComponent({
    propsData: {
      target: el,
      user,
      show: true,
      placement: el.dataset.placement || 'top',
      container: el.parentNode?.id || null,
    },
  });
}

// Helper function to manage focus within popover
function setupPopoverFocus(popoverInstance, triggerElement) {
  const { popoverId } = triggerElement.dataset;
  const popoverElement = document.getElementById(popoverId);
  const focusableElements = popoverElement?.querySelectorAll('button, a') || [];
  const allFocusable = Array.from(
    document.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])',
    ),
  ).filter((el) => el.offsetParent !== null);
  const trigger = document.querySelector(`[data-popover-id="${popoverId}"]`);
  const triggerIndex = allFocusable?.indexOf(trigger);

  // Clean up any existing focus listeners on the trigger element
  if (triggerElement.focusCleanup) {
    triggerElement.focusCleanup();
  }

  // Add immediate global focus trap prevention
  const globalFocusTrapPrevention = (event) => {
    if (!popoverId || !popoverElement) return;

    const { target } = event;

    // If focus is moving into the popover area
    if (popoverElement.contains(target) || target === popoverElement) {
      if (focusableElements.length > 0) {
        // Check if the target is one of the focusable elements
        const isFocusableElement = Array.from(focusableElements).includes(target);
        if (!isFocusableElement) {
          // Focus went to popover but not to a focusable element, redirect to first focusable element
          event.preventDefault();
          focusableElements[0].focus();
        }
      } else {
        // No focusable elements - redirect focus away from popover
        event.preventDefault();
        const nextElement = allFocusable[triggerIndex + 1];

        if (nextElement) {
          nextElement.focus();
        } else if (allFocusable[0]) {
          allFocusable[0].focus();
        } else if (trigger) {
          trigger.focus();
        }
      }
    }
  };

  const handleEscapeKey = (event) => {
    if (event.key === 'Escape') {
      event.preventDefault();
      // eslint-disable-next-line no-underscore-dangle
      if (popoverInstance && !popoverInstance._isDestroyed) {
        // Mark element as recently closed to prevent immediate reopening
        // eslint-disable-next-line no-param-reassign
        triggerElement.dataset.popoverRecentlyClosed = 'true';
        setTimeout(() => {
          // eslint-disable-next-line no-param-reassign
          delete triggerElement.dataset.popoverRecentlyClosed;
        }, 500);

        popoverInstance.$destroy();
      }
      if (triggerElement) {
        triggerElement.focus();
      }
    }
  };

  const immediateFastTabHandler = (event) => {
    if (event.key === 'Tab') {
      if (!popoverId || !popoverElement) return;

      const { target } = event;

      if (target === triggerElement) {
        if (!event.shiftKey && focusableElements.length > 0) {
          // Tab forward into popover
          event.preventDefault();
          focusableElements[0].focus();
        }
      }
      // If tabbing within popover
      else if (popoverElement.contains(target)) {
        if (focusableElements.length === 0) {
          event.preventDefault();
          const nextElement = event.shiftKey ? trigger : allFocusable[triggerIndex + 1];

          if (nextElement) {
            nextElement.focus();
          } else if (allFocusable[0]) {
            allFocusable[0].focus();
          }
        } else {
          // Has focusable elements - handle navigation
          const firstFocusable = focusableElements[0];
          const lastFocusable = focusableElements[focusableElements.length - 1];

          if (event.shiftKey && target === firstFocusable) {
            // Shift+Tab from first element - go to trigger
            event.preventDefault();
            if (trigger) {
              trigger.focus();
            }
          } else if (!event.shiftKey && target === lastFocusable) {
            // Tab from last element - go to next element after trigger
            event.preventDefault();
            const nextElement = allFocusable[triggerIndex + 1];

            if (nextElement) {
              nextElement.focus();
            } else if (allFocusable[0]) {
              allFocusable[0].focus();
            }
          }
        }
      }
    }
  };

  // Add immediate handlers
  document.addEventListener('focusin', globalFocusTrapPrevention, true); // Use capture phase
  document.addEventListener('keydown', handleEscapeKey);
  document.addEventListener('keydown', immediateFastTabHandler);

  // Store cleanup function on the trigger element
  // eslint-disable-next-line no-param-reassign
  triggerElement.focusCleanup = () => {
    document.removeEventListener('focusin', globalFocusTrapPrevention, true);
    document.removeEventListener('keydown', handleEscapeKey);
    document.removeEventListener('keydown', immediateFastTabHandler);
  };

  // Wait for popover to be mounted and rendered, then wait a bit more for DOM updates
  const waitForPopover = () => {
    if (!popoverId) {
      setTimeout(waitForPopover, USER_POPOVER_DELAY);
      return;
    }

    if (!popoverElement) {
      // If popover element doesn't exist yet, wait and try again
      setTimeout(waitForPopover, USER_POPOVER_DELAY);
      return;
    }

    // The immediate handlers are sufficient for fast tabbing
    // Keep them as the primary handlers since they're more robust

    // Clean up when popover is destroyed
    popoverInstance.$once('hook:beforeDestroy', () => {
      document.removeEventListener('focusin', globalFocusTrapPrevention, true);
      document.removeEventListener('keydown', handleEscapeKey);
      document.removeEventListener('keydown', immediateFastTabHandler);
      // eslint-disable-next-line no-param-reassign
      triggerElement.focusCleanup = null;
    });
  };

  // Start waiting for the popover after Vue's next tick
  popoverInstance.$nextTick(() => {
    // Add additional delay to account for any animations or async mounting
    setTimeout(waitForPopover, USER_POPOVER_DELAY);
  });
}

function launchPopover(el, mountPopover) {
  if (el.dataset.popoverRecentlyClosed) {
    return;
  }

  // Check if popover already exists by looking for the popover ID
  if (el.dataset.popoverId) {
    // If popover already exists, just set up focus management again
    const existingPopoverElement = document.getElementById(el.dataset.popoverId);
    if (existingPopoverElement) {
      // Find the existing popover instance (we need to store it on the element)
      if (el.popoverInstance) {
        setupPopoverFocus(el.popoverInstance, el);
      }
      return;
    }
  }

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

  const popoverInstance = createPopover(el, Vue.observable(emptyUser));
  const { userId } = el.dataset;

  el.popoverInstance = popoverInstance;

  popoverInstance.$on('follow', () => {
    UsersCache.updateById(userId, { is_followed: true });
    el.user.isFollowed = true;
  });

  popoverInstance.$on('unfollow', () => {
    UsersCache.updateById(userId, { is_followed: false });
    el.user.isFollowed = false;
  });

  mountPopover(popoverInstance);

  popoverInstance.$nextTick(() => {
    window.requestAnimationFrame(() => {
      // Find the actual popover element by looking for Bootstrap Vue popover structure
      const popoverElements = document.querySelectorAll('[id^="__bv_popover_"]');
      let actualPopoverId = null;

      // Find the popover that belongs to this instance
      for (const popoverEl of popoverElements) {
        const popoverTarget = popoverEl.querySelector('[data-original-title], .popover-body');
        if (popoverTarget && !popoverEl.dataset.claimed) {
          popoverEl.dataset.claimed = 'true';
          actualPopoverId = popoverEl.id;
          break;
        }
      }

      el.dataset.popoverId = actualPopoverId;

      setupPopoverFocus(popoverInstance, el);
    });
  });

  // Reset user property and popover ID when popover is destroyed
  popoverInstance.$once('hook:beforeDestroy', () => {
    el.user = null;
    el.popoverInstance = null;
    delete el.dataset.popoverId;
  });
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
