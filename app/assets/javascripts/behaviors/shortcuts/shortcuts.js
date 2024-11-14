import $ from 'jquery';
import { flatten } from 'lodash';
import Vue from 'vue';
import { InternalEvents } from '~/tracking';
import { FIND_FILE_SHORTCUT_CLICK } from '~/tracking/constants';
import { Mousetrap, addStopCallback } from '~/lib/mousetrap';
import { getCookie, setCookie, parseBoolean } from '~/lib/utils/common_utils';
import { waitForElement } from '~/lib/utils/dom_utils';
import findAndFollowLink from '~/lib/utils/navigation_utility';
import { refreshCurrentPage } from '~/lib/utils/url_utility';
import {
  keysFor,
  TOGGLE_KEYBOARD_SHORTCUTS_DIALOG,
  START_SEARCH,
  START_SEARCH_PROJECT_FILE,
  FOCUS_FILTER_BAR,
  TOGGLE_PERFORMANCE_BAR,
  HIDE_APPEARING_CONTENT,
  TOGGLE_CANARY,
  TOGGLE_MARKDOWN_PREVIEW,
  FIND_AND_REPLACE,
  GO_TO_YOUR_TODO_LIST,
  GO_TO_ACTIVITY_FEED,
  GO_TO_YOUR_ISSUES,
  GO_TO_YOUR_MERGE_REQUESTS,
  GO_TO_YOUR_PROJECTS,
  GO_TO_YOUR_GROUPS,
  GO_TO_MILESTONE_LIST,
  GO_TO_YOUR_SNIPPETS,
  GO_TO_YOUR_REVIEW_REQUESTS,
} from './keybindings';
import { disableShortcuts, shouldDisableShortcuts } from './shortcuts_toggle';

/**
 * The key used to save and fetch the local Mousetrap instance
 * attached to a `<textarea>` element using `jQuery.data`
 */
export const LOCAL_MOUSETRAP_DATA_KEY = 'local-mousetrap-instance';

/**
 * Gets a mapping of toolbar button => keyboard shortcuts
 * associated to the given markdown editor `<textarea>` element
 *
 * @param {HTMLTextAreaElement} $textarea The jQuery-wrapped `<textarea>`
 * element to extract keyboard shortcuts from
 *
 * @returns A Map with keys that are jQuery-wrapped toolbar buttons
 * (i.e. `$toolbarBtn`) and values that are arrays of string
 * keyboard shortcuts (e.g. `['command+k', 'ctrl+k]`).
 */
function getToolbarBtnToShortcutsMap($textarea) {
  const $allToolbarBtns = $textarea.closest('.md-area').find('.js-md');
  const map = new Map();

  $allToolbarBtns.each(function attachToolbarBtnHandler() {
    const $toolbarBtn = $(this);
    const keyboardShortcuts = $toolbarBtn.data('md-shortcuts');

    if (keyboardShortcuts?.length) {
      map.set($toolbarBtn, keyboardShortcuts);
    }
  });

  return map;
}

export default class Shortcuts {
  constructor() {
    if (process.env.NODE_ENV !== 'production' && this.constructor !== Shortcuts) {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      throw new Error('Shortcuts cannot be subclassed.');
    }

    this.extensions = new Map();
    this.onToggleHelp = this.onToggleHelp.bind(this);
    this.helpModalElement = null;
    this.helpModalVueInstance = null;

    this.addAll([
      [TOGGLE_KEYBOARD_SHORTCUTS_DIALOG, this.onToggleHelp],
      [START_SEARCH_PROJECT_FILE, Shortcuts.focusSearchFile],
      [START_SEARCH, Shortcuts.focusSearch],
      [FOCUS_FILTER_BAR, this.focusFilter.bind(this)],
      [TOGGLE_PERFORMANCE_BAR, Shortcuts.onTogglePerfBar],
      [HIDE_APPEARING_CONTENT, Shortcuts.hideAppearingContent],
      [TOGGLE_CANARY, Shortcuts.onToggleCanary],

      [GO_TO_YOUR_TODO_LIST, () => findAndFollowLink('.shortcuts-todos')],
      [GO_TO_ACTIVITY_FEED, () => findAndFollowLink('.dashboard-shortcuts-activity')],
      [GO_TO_YOUR_ISSUES, () => findAndFollowLink('.dashboard-shortcuts-issues')],
      [
        GO_TO_YOUR_MERGE_REQUESTS,
        () =>
          findAndFollowLink(
            '.dashboard-shortcuts-merge_requests, .js-merge-request-dashboard-shortcut',
          ),
      ],
      [
        GO_TO_YOUR_REVIEW_REQUESTS,
        () =>
          findAndFollowLink(
            '.dashboard-shortcuts-review_requests, .js-merge-request-dashboard-shortcut',
          ),
      ],
      [GO_TO_YOUR_PROJECTS, () => findAndFollowLink('.dashboard-shortcuts-projects')],
      [GO_TO_YOUR_GROUPS, () => findAndFollowLink('.dashboard-shortcuts-groups')],
      [GO_TO_MILESTONE_LIST, () => findAndFollowLink('.dashboard-shortcuts-milestones')],
      [GO_TO_YOUR_SNIPPETS, () => findAndFollowLink('.dashboard-shortcuts-snippets')],

      [TOGGLE_MARKDOWN_PREVIEW, Shortcuts.toggleMarkdownPreview],
    ]);

    addStopCallback((e, element, combo) =>
      keysFor(TOGGLE_MARKDOWN_PREVIEW).includes(combo) ? false : undefined,
    );

    if (gon?.features?.findAndReplace) {
      this.add(FIND_AND_REPLACE, Shortcuts.toggleFindAndReplaceBar);

      addStopCallback((e, element, combo) =>
        keysFor(FIND_AND_REPLACE).includes(combo) ? false : undefined,
      );
    }

    $(document).on('click', '.js-shortcuts-modal-trigger', this.onToggleHelp);

    if (shouldDisableShortcuts()) {
      disableShortcuts();
    }
  }

  /**
   * Instantiate a legacy shortcut extension class.
   *
   * NOTE: The preferred approach for adding shortcuts is described in
   * https://docs.gitlab.com/ee/development/fe_guide/keyboard_shortcuts.html.
   * This method is only for existing legacy shortcut classes.
   *
   * A shortcut extension class packages up several shortcuts and behaviors for
   * a page or set of pages. They are considered legacy because they usually do
   * not follow modern best practices. For instance, they may hook into the UI
   * in brittle ways, e.g.. querySelectors.
   *
   * Extension classes can declare dependencies on other shortcut extension
   * classes by listing them in a static `dependencies` property. This is
   * essentially a reimplementation of the previous subclassing approach, but
   * with idempotency: a shortcut extension class can now only be added at most
   * one time.
   *
   * Extension classes are instantiated and given the Shortcuts singleton
   * instance as their first argument. If the class constructor needs
   * additional arguments, pass them via the second argument as an array.
   *
   * See https://gitlab.com/gitlab-org/gitlab/-/issues/392845 for more context.
   *
   * @param {Function} Extension The extension class to add/instantiate.
   * @param {Array} [args] A list of additional args to pass to the extension
   *     class constructor.
   * @param {Set} [extensionsCurrentlyLoading] For internal use only. Do not
   *     use.
   * @returns The instantiated shortcut extension class.
   */
  addExtension(Extension, args = [], extensionsCurrentlyLoading = new Set()) {
    extensionsCurrentlyLoading.add(Extension);

    let instance = this.extensions.get(Extension);
    if (!instance) {
      for (const Dep of Extension.dependencies ?? []) {
        if (extensionsCurrentlyLoading.has(Dep) || Dep === Shortcuts) {
          // We've encountered a circular dependency, so stop recursing.
          // eslint-disable-next-line no-continue
          continue;
        }

        extensionsCurrentlyLoading.add(Dep);

        this.addExtension(Dep, [], extensionsCurrentlyLoading);
      }

      instance = new Extension(this, ...args);
      this.extensions.set(Extension, instance);
    }

    extensionsCurrentlyLoading.delete(Extension);
    return instance;
  }

  /**
   * Bind the keyboard shortcut(s) defined by the given command to the given
   * callback.
   *
   * @param {Object} command A command object.
   * @param {Function} callback The callback to call when the command's key
   *     combo has been pressed.
   * @returns {void}
   */
  // eslint-disable-next-line class-methods-use-this
  add(command, callback) {
    Mousetrap.bind(keysFor(command), callback);
  }

  /**
   * Bind the keyboard shortcut(s) defined by the given commands to the given
   * callbacks.
   *
   * @param {Array<[Object, Function]>} commandsAndCallbacks An array of
   *     command/callback pairs.
   * @returns {void}
   */
  addAll(commandsAndCallbacks) {
    commandsAndCallbacks.forEach((commandAndCallback) => this.add(...commandAndCallback));
  }

  onToggleHelp(e) {
    if (e?.preventDefault) {
      e.preventDefault();
    }

    if (this.helpModalElement && this.helpModalVueInstance) {
      this.helpModalVueInstance.$destroy();
      this.helpModalElement.remove();
      this.helpModalElement = null;
      this.helpModalVueInstance = null;
    } else {
      this.helpModalElement = document.createElement('div');
      document.body.append(this.helpModalElement);

      this.helpModalVueInstance = new Vue({
        el: this.helpModalElement,
        components: {
          ShortcutsHelp: () => import('./shortcuts_help.vue'),
        },
        render: (createElement) => {
          return createElement('shortcuts-help', {
            on: {
              hidden: this.onToggleHelp,
            },
          });
        },
      });
    }
  }

  static onTogglePerfBar(e) {
    e.preventDefault();
    const performanceBarCookieName = 'perf_bar_enabled';
    if (parseBoolean(getCookie(performanceBarCookieName))) {
      setCookie(performanceBarCookieName, 'false', { path: '/' });
    } else {
      setCookie(performanceBarCookieName, 'true', { path: '/' });
    }
    refreshCurrentPage();
  }

  static onToggleCanary(e) {
    e.preventDefault();
    const canaryCookieName = 'gitlab_canary';
    const currentValue = parseBoolean(getCookie(canaryCookieName));
    setCookie(canaryCookieName, (!currentValue).toString(), { expires: 365, path: '/' });
    refreshCurrentPage();
  }

  static toggleMarkdownPreview(e) {
    $(document).triggerHandler('markdown-preview:toggle', [e]);
  }

  static toggleFindAndReplaceBar(e) {
    $(document).triggerHandler('markdown-editor:find-and-replace', [e]);
  }

  focusFilter(e) {
    if (!this.filterInput) {
      this.filterInput = $('input[type=search]', '.nav-controls');
    }
    this.filterInput.focus();
    e.preventDefault();
  }

  static focusSearch(e) {
    document.querySelector('#super-sidebar-search')?.click();
    InternalEvents.trackEvent('press_keyboard_shortcut_to_activate_command_palette');

    if (e.preventDefault) {
      e.preventDefault();
    }
  }

  static async focusSearchFile(e) {
    if (e?.key) {
      InternalEvents.trackEvent(FIND_FILE_SHORTCUT_CLICK);
    }
    e?.preventDefault();
    document.querySelector('#super-sidebar-search')?.click();

    const searchInput = await waitForElement('#super-sidebar-search-modal #search');
    if (!searchInput) return;

    const currentPath = document.querySelector('.js-repo-breadcrumbs')?.dataset.currentPath;

    searchInput.value = `~${currentPath ? `${currentPath}/` : ''}`;
    searchInput.dispatchEvent(new Event('input'));
  }

  static hideAppearingContent(e) {
    const elements = document.querySelectorAll('.tooltip, .popover');

    elements.forEach((element) => {
      element.style.display = 'none';
    });

    if (e.preventDefault) {
      e.preventDefault();
    }
  }

  /**
   * Initializes markdown editor shortcuts on the provided `<textarea>` element
   *
   * @param {JQuery} $textarea The jQuery-wrapped `<textarea>` element
   * where markdown shortcuts should be enabled
   * @param {Function} handler The handler to call when a
   * keyboard shortcut is pressed inside the markdown `<textarea>`
   */
  static initMarkdownEditorShortcuts($textarea, handler) {
    const toolbarBtnToShortcutsMap = getToolbarBtnToShortcutsMap($textarea);

    const localMousetrap = new Mousetrap($textarea[0]);

    // Save a reference to the local mousetrap instance on the <textarea>
    // so that it can be retrieved when unbinding shortcut handlers
    $textarea.data(LOCAL_MOUSETRAP_DATA_KEY, localMousetrap);

    toolbarBtnToShortcutsMap.forEach((keyboardShortcuts, $toolbarBtn) => {
      localMousetrap.bind(keyboardShortcuts, (e) => {
        e.preventDefault();

        handler($toolbarBtn);
      });
    });

    // Get an array of all shortcut strings that have been added above
    const allShortcuts = flatten([...toolbarBtnToShortcutsMap.values()]);

    const originalStopCallback = Mousetrap.prototype.stopCallback;
    localMousetrap.stopCallback = function newStopCallback(e, element, combo) {
      if (allShortcuts.includes(combo)) {
        return false;
      }

      return originalStopCallback.call(this, e, element, combo);
    };
  }

  /**
   * Removes markdown editor shortcut handlers originally attached
   * with `initMarkdownEditorShortcuts`.
   *
   * Note: it is safe to call this function even if `initMarkdownEditorShortcuts`
   * has _not_ yet been called on the given `<textarea>`.
   *
   * @param {JQuery} $textarea The jQuery-wrapped `<textarea>`
   * to remove shortcut handlers from
   */
  static removeMarkdownEditorShortcuts($textarea) {
    const localMousetrap = $textarea.data(LOCAL_MOUSETRAP_DATA_KEY);

    if (localMousetrap) {
      getToolbarBtnToShortcutsMap($textarea).forEach((keyboardShortcuts) => {
        localMousetrap.unbind(keyboardShortcuts);
      });
    }
  }
}
