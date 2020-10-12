import $ from 'jquery';
import Cookies from 'js-cookie';
import Mousetrap from 'mousetrap';
import Vue from 'vue';
import { flatten } from 'lodash';
import { disableShortcuts, shouldDisableShortcuts } from './shortcuts_toggle';
import ShortcutsToggle from './shortcuts_toggle.vue';
import axios from '../../lib/utils/axios_utils';
import { refreshCurrentPage, visitUrl } from '../../lib/utils/url_utility';
import findAndFollowLink from '../../lib/utils/navigation_utility';
import { parseBoolean, getCspNonceValue } from '~/lib/utils/common_utils';
import { keysFor, TOGGLE_PERFORMANCE_BAR } from './keybindings';

const defaultStopCallback = Mousetrap.prototype.stopCallback;
Mousetrap.prototype.stopCallback = function customStopCallback(e, element, combo) {
  if (['ctrl+shift+p', 'command+shift+p'].indexOf(combo) !== -1) {
    return false;
  }

  return defaultStopCallback.call(this, e, element, combo);
};

function initToggleButton() {
  return new Vue({
    el: document.querySelector('.js-toggle-shortcuts'),
    render(createElement) {
      return createElement(ShortcutsToggle);
    },
  });
}

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
    this.enabledHelp = [];

    Mousetrap.bind('?', this.onToggleHelp);
    Mousetrap.bind('s', Shortcuts.focusSearch);
    Mousetrap.bind('/', Shortcuts.focusSearch);
    Mousetrap.bind('f', this.focusFilter.bind(this));
    Mousetrap.bind(keysFor(TOGGLE_PERFORMANCE_BAR), Shortcuts.onTogglePerfBar);

    const findFileURL = document.body.dataset.findFile;

    Mousetrap.bind('shift+t', () => findAndFollowLink('.shortcuts-todos'));
    Mousetrap.bind('shift+a', () => findAndFollowLink('.dashboard-shortcuts-activity'));
    Mousetrap.bind('shift+i', () => findAndFollowLink('.dashboard-shortcuts-issues'));
    Mousetrap.bind('shift+m', () => findAndFollowLink('.dashboard-shortcuts-merge_requests'));
    Mousetrap.bind('shift+p', () => findAndFollowLink('.dashboard-shortcuts-projects'));
    Mousetrap.bind('shift+g', () => findAndFollowLink('.dashboard-shortcuts-groups'));
    Mousetrap.bind('shift+l', () => findAndFollowLink('.dashboard-shortcuts-milestones'));
    Mousetrap.bind('shift+s', () => findAndFollowLink('.dashboard-shortcuts-snippets'));

    Mousetrap.bind(['ctrl+shift+p', 'command+shift+p'], Shortcuts.toggleMarkdownPreview);

    if (typeof findFileURL !== 'undefined' && findFileURL !== null) {
      Mousetrap.bind('t', () => {
        visitUrl(findFileURL);
      });
    }

    $(document).on('click.more_help', '.js-more-help-button', function clickMoreHelp(e) {
      $(this).remove();
      e.preventDefault();
    });

    $('.js-shortcuts-modal-trigger')
      .off('click')
      .on('click', this.onToggleHelp);

    if (shouldDisableShortcuts()) {
      disableShortcuts();
    }
  }

  onToggleHelp(e) {
    if (e.preventDefault) {
      e.preventDefault();
    }

    Shortcuts.toggleHelp(this.enabledHelp);
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

  static toggleMarkdownPreview(e) {
    // Check if short-cut was triggered while in Write Mode
    const $target = $(e.target);
    const $form = $target.closest('form');

    if ($target.hasClass('js-note-text')) {
      $('.js-md-preview-button', $form).focus();
    }
    $(document).triggerHandler('markdown-preview:toggle', [e]);
  }

  static toggleHelp(location) {
    const $modal = $('#modal-shortcuts');

    if ($modal.length) {
      $modal.modal('toggle');
      return null;
    }

    return axios
      .get(gon.shortcuts_path, {
        responseType: 'text',
      })
      .then(({ data }) => {
        $.globalEval(data, { nonce: getCspNonceValue() });

        if (location && location.length > 0) {
          const results = [];
          for (let i = 0, len = location.length; i < len; i += 1) {
            results.push($(location[i]).show());
          }
          return results;
        }

        return $('.js-more-help-button').remove();
      })
      .then(initToggleButton);
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
      localMousetrap.bind(keyboardShortcuts, e => {
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
      getToolbarBtnToShortcutsMap($textarea).forEach(keyboardShortcuts => {
        localMousetrap.unbind(keyboardShortcuts);
      });
    }
  }
}
