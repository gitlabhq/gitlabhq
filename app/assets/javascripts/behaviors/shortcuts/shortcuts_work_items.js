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
      [ISSUE_MR_CHANGE_ASSIGNEE, () => ShortcutsWorkItem.openSidebarDropdown('assignee')],
      [ISSUE_MR_CHANGE_MILESTONE, () => ShortcutsWorkItem.openSidebarDropdown('milestone')],
      [ISSUABLE_CHANGE_LABEL, () => ShortcutsWorkItem.openSidebarDropdown('labels')],
      [ISSUABLE_EDIT_DESCRIPTION, ShortcutsWorkItem.editDescription],
      [ISSUABLE_COPY_REF, () => this.copyReference()],
    ]);
  }

  static openSidebarDropdown(name) {
    setTimeout(() => {
      const editBtn = document.querySelector(`.js-${name} .shortcut-sidebar-dropdown-toggle`);
      editBtn?.click();
    }, DEBOUNCE_DROPDOWN_DELAY);
    return false;
  }

  static editDescription() {
    // Need to click the element as on issues, editing is inline
    // on merge request, editing is on a different page
    document.querySelector('.shortcut-edit-wi-description')?.click();

    return false;
  }

  async copyReference() {
    const refButton = document.querySelector('.shortcut-copy-reference');
    const copiedRef = refButton?.dataset.clipboardText;

    if (copiedRef) {
      this.refInMemoryButton.dataset.clipboardText = copiedRef;

      this.refInMemoryButton.dispatchEvent(new CustomEvent('click'));
    }
  }
}
