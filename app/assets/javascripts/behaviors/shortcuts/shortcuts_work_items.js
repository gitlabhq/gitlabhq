import ClipboardJS from 'clipboard';
import toast from '~/vue_shared/plugins/global_toast';
import { s__ } from '~/locale';
import { DEBOUNCE_DROPDOWN_DELAY } from '~/sidebar/components/labels/labels_select_widget/constants';
import {
  ISSUE_MR_CHANGE_ASSIGNEE,
  ISSUE_MR_CHANGE_MILESTONE,
  ISSUABLE_CHANGE_LABEL,
  ISSUABLE_EDIT_DESCRIPTION,
  ISSUABLE_COPY_REF,
  WORK_ITEM_TOGGLE_SIDEBAR,
} from './keybindings';

export default class ShortcutsWorkItem {
  constructor(shortcuts) {
    this.refInMemoryButton = document.createElement('button');
    this.refClipboardInstance = new ClipboardJS(this.refInMemoryButton);
    this.refClipboardInstance.on('success', () => {
      toast(s__('GlobalShortcuts|Copied reference to clipboard.'));
    });
    this.refClipboardInstance.on('error', () => {
      toast(s__('GlobalShortcuts|Unable to copy the reference at this time.'));
    });

    shortcuts.addAll([
      [ISSUE_MR_CHANGE_ASSIGNEE, () => ShortcutsWorkItem.openSidebarDropdown('js-assignee')],
      [ISSUE_MR_CHANGE_MILESTONE, () => ShortcutsWorkItem.openSidebarDropdown('js-milestone')],
      [ISSUABLE_CHANGE_LABEL, () => ShortcutsWorkItem.openSidebarDropdown('js-labels')],
      [ISSUABLE_EDIT_DESCRIPTION, ShortcutsWorkItem.editDescription],
      [WORK_ITEM_TOGGLE_SIDEBAR, ShortcutsWorkItem.toggleSidebar],
      [ISSUABLE_COPY_REF, () => this.copyReference()],
    ]);

    /**
     * We're attaching a global focus event listener on document for
     * every markdown input field.
     */
    document.addEventListener('focus', this.handleMarkdownFieldFocus);
  }

  destroy() {
    document.removeEventListener('focus', this.handleMarkdownFieldFocus);
  }

  /**
   * This event handler preserves last focused markdown input field.
   * @param {Object} event
   */
  static handleMarkdownFieldFocus({ target }) {
    if (target.matches('.js-vue-markdown-field .js-gfm-input')) {
      ShortcutsWorkItem.lastFocusedReplyField = target;
    }
  }

  static openSidebarDropdown(selector) {
    setTimeout(() => {
      const shortcutSelector = `.${selector} .shortcut-sidebar-dropdown-toggle`;
      const editBtn =
        document.querySelector(`.work-item-drawer ${shortcutSelector}`) ||
        document.querySelector(`.modal ${shortcutSelector}`) ||
        document.querySelector(shortcutSelector);
      editBtn?.click();
    }, DEBOUNCE_DROPDOWN_DELAY);
    return false;
  }

  static editDescription() {
    // Need to click the element as on issues, editing is inline
    // on merge request, editing is on a different page
    const editDescriptionSelector = '.shortcut-edit-wi-description';
    const editButton =
      document.querySelector(`.work-item-drawer ${editDescriptionSelector}`) ||
      document.querySelector(`.modal ${editDescriptionSelector}`) ||
      document.querySelector(editDescriptionSelector);

    editButton?.click();

    return false;
  }

  static toggleSidebar() {
    // Need to click the button within the actions dropdown item
    const sidebarBtn = document.querySelector('.js-sidebar-toggle-action button');

    sidebarBtn?.click();

    return false;
  }

  async copyReference() {
    const refSelector = '.shortcut-copy-reference';
    const refButton =
      document.querySelector(`.work-item-drawer ${refSelector}`) ||
      document.querySelector(`.modal ${refSelector}`) ||
      document.querySelector(refSelector);
    const copiedRef = refButton?.dataset.clipboardText;

    if (copiedRef) {
      this.refInMemoryButton.dataset.clipboardText = copiedRef;

      this.refInMemoryButton.dispatchEvent(new CustomEvent('click'));
    }
  }
}
