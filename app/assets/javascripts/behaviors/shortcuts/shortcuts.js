import $ from 'jquery';
import Cookies from 'js-cookie';
import { flatten } from 'lodash';
import Mousetrap from 'mousetrap';
import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import findAndFollowLink from '~/lib/utils/navigation_utility';
import { refreshCurrentPage, visitUrl } from '~/lib/utils/url_utility';
import {
  keysFor,
  TOGGLE_KEYBOARD_SHORTCUTS_DIALOG,
  START_SEARCH,
  FOCUS_FILTER_BAR,
  TOGGLE_PERFORMANCE_BAR,
  HIDE_APPEARING_CONTENT,
  TOGGLE_CANARY,
  TOGGLE_MARKDOWN_PREVIEW,
  GO_TO_YOUR_TODO_LIST,
  GO_TO_ACTIVITY_FEED,
  GO_TO_YOUR_ISSUES,
  GO_TO_YOUR_MERGE_REQUESTS,
  GO_TO_YOUR_PROJECTS,
  GO_TO_YOUR_GROUPS,
  GO_TO_MILESTONE_LIST,
  GO_TO_YOUR_SNIPPETS,
  GO_TO_PROJECT_FIND_FILE,
} from './keybindings';
import { disableShortcuts, shouldDisableShortcuts } from './shortcuts_toggle';

const defaultStopCallback = Mousetrap.prototype.stopCallback;
Mousetrap.prototype.stopCallback = function customStopCallback(e, element, combo) {
  if (keysFor(TOGGLE_MARKDOWN_PREVIEW).indexOf(combo) !== -1) {
    return false;
  }

  return defaultStopCallback.call(this, e, element, combo);
};

/**
 * The key used to save and fetch the local Mousetrap instance
 * attached to a `<textarea>` element using `jQuery.data`
 */
const LOCAL_MOUSETRAP_DATA_KEY = 'local-mousetrap-instance';

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
    this.onToggleHelp = this.onToggleHelp.bind(this);
    this.helpModalElement = null;
    this.helpModalVueInstance = null;

    Mousetrap.bind(keysFor(TOGGLE_KEYBOARD_SHORTCUTS_DIALOG), this.onToggleHelp);
    Mousetrap.bind(keysFor(START_SEARCH), Shortcuts.focusSearch);
    Mousetrap.bind(keysFor(FOCUS_FILTER_BAR), this.focusFilter.bind(this));
    Mousetrap.bind(keysFor(TOGGLE_PERFORMANCE_BAR), Shortcuts.onTogglePerfBar);
    Mousetrap.bind(keysFor(HIDE_APPEARING_CONTENT), Shortcuts.hideAppearingContent);
    Mousetrap.bind(keysFor(TOGGLE_CANARY), Shortcuts.onToggleCanary);

    const findFileURL = document.body.dataset.findFile;

    Mousetrap.bind(keysFor(GO_TO_YOUR_TODO_LIST), () => findAndFollowLink('.shortcuts-todos'));
    Mousetrap.bind(keysFor(GO_TO_ACTIVITY_FEED), () =>
      findAndFollowLink('.dashboard-shortcuts-activity'),
    );
    Mousetrap.bind(keysFor(GO_TO_YOUR_ISSUES), () =>
      findAndFollowLink('.dashboard-shortcuts-issues'),
    );
    Mousetrap.bind(keysFor(GO_TO_YOUR_MERGE_REQUESTS), () =>
      findAndFollowLink('.dashboard-shortcuts-merge_requests'),
    );
    Mousetrap.bind(keysFor(GO_TO_YOUR_PROJECTS), () =>
      findAndFollowLink('.dashboard-shortcuts-projects'),
    );
    Mousetrap.bind(keysFor(GO_TO_YOUR_GROUPS), () =>
      findAndFollowLink('.dashboard-shortcuts-groups'),
    );
    Mousetrap.bind(keysFor(GO_TO_MILESTONE_LIST), () =>
      findAndFollowLink('.dashboard-shortcuts-milestones'),
    );
    Mousetrap.bind(keysFor(GO_TO_YOUR_SNIPPETS), () =>
      findAndFollowLink('.dashboard-shortcuts-snippets'),
    );

    Mousetrap.bind(keysFor(TOGGLE_MARKDOWN_PREVIEW), Shortcuts.toggleMarkdownPreview);

    if (typeof findFileURL !== 'undefined' && findFileURL !== null) {
      Mousetrap.bind(keysFor(GO_TO_PROJECT_FIND_FILE), () => {
        visitUrl(findFileURL);
      });
    }

    $(document).on('click.more_help', '.js-more-help-button', function clickMoreHelp(e) {
      $(this).remove();
      e.preventDefault();
    });

    // eslint-disable-next-line @gitlab/no-global-event-off
    $('.js-shortcuts-modal-trigger').off('click').on('click', this.onToggleHelp);

    if (shouldDisableShortcuts()) {
      disableShortcuts();
    }
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
    if (parseBoolean(Cookies.get(performanceBarCookieName))) {
      Cookies.set(performanceBarCookieName, 'false', { expires: 365, path: '/' });
    } else {
      Cookies.set(performanceBarCookieName, 'true', { expires: 365, path: '/' });
    }
    refreshCurrentPage();
  }

  static onToggleCanary(e) {
    e.preventDefault();
    const canaryCookieName = 'gitlab_canary';
    const currentValue = parseBoolean(Cookies.get(canaryCookieName));
    Cookies.set(canaryCookieName, (!currentValue).toString(), { expires: 365, path: '/' });
    refreshCurrentPage();
  }

  static toggleMarkdownPreview(e) {
    // Check if short-cut was triggered while in Write Mode
    const $target = $(e.target);
    const $form = $target.closest('form');

    if ($target.hasClass('js-note-text')) {
      $('.js-md-preview-button', $form).focus();
    }
    $(document).triggerHandler('markdown-preview:toggle', [e]);
  }

  focusFilter(e) {
    if (!this.filterInput) {
      this.filterInput = $('input[type=search]', '.nav-controls');
    }
    this.filterInput.focus();
    e.preventDefault();
  }

  static focusSearch(e) {
    $('#search').focus();

    if (e.preventDefault) {
      e.preventDefault();
    }
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
