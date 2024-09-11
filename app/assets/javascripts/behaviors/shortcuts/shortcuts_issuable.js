import ClipboardJS from 'clipboard';
import { DEBOUNCE_DROPDOWN_DELAY } from '~/sidebar/components/labels/labels_select_widget/constants';
import toast from '~/vue_shared/plugins/global_toast';
import { s__ } from '~/locale';
import Sidebar from '~/right_sidebar';
import {
  ISSUE_MR_CHANGE_ASSIGNEE,
  ISSUE_MR_CHANGE_MILESTONE,
  ISSUABLE_CHANGE_LABEL,
  ISSUABLE_EDIT_DESCRIPTION,
  MR_COPY_SOURCE_BRANCH_NAME,
  ISSUABLE_COPY_REF,
} from './keybindings';

export default class ShortcutsIssuable {
  constructor(shortcuts) {
    this.branchInMemoryButton = document.createElement('button');
    this.branchClipboardInstance = new ClipboardJS(this.branchInMemoryButton);
    this.branchClipboardInstance.on('success', () => {
      toast(s__('GlobalShortcuts|Copied source branch name to clipboard.'));
    });
    this.branchClipboardInstance.on('error', () => {
      toast(s__('GlobalShortcuts|Unable to copy the source branch name at this time.'));
    });

    this.refInMemoryButton = document.createElement('button');
    this.refClipboardInstance = new ClipboardJS(this.refInMemoryButton);
    this.refClipboardInstance.on('success', () => {
      toast(s__('GlobalShortcuts|Copied reference to clipboard.'));
    });
    this.refClipboardInstance.on('error', () => {
      toast(s__('GlobalShortcuts|Unable to copy the reference at this time.'));
    });

    shortcuts.addAll([
      [ISSUE_MR_CHANGE_ASSIGNEE, () => ShortcutsIssuable.openSidebarDropdown('assignee')],
      [ISSUE_MR_CHANGE_MILESTONE, () => ShortcutsIssuable.openSidebarDropdown('milestone')],
      [ISSUABLE_CHANGE_LABEL, () => ShortcutsIssuable.openSidebarDropdown('labels')],
      [ISSUABLE_EDIT_DESCRIPTION, ShortcutsIssuable.editIssue],
      [MR_COPY_SOURCE_BRANCH_NAME, () => this.copyBranchName()],
      [ISSUABLE_COPY_REF, () => this.copyIssuableRef()],
    ]);
  }

  static editIssue() {
    // Need to click the element as on issues, editing is inline
    // on merge request, editing is on a different page
    document.querySelector('.js-issuable-edit').click();

    return false;
  }

  static openSidebarDropdown(name) {
    Sidebar.instance.openDropdown(name);
    // Wait for the sidebar to trigger('click') open
    // so it doesn't cause our dropdown to close preemptively
    setTimeout(() => {
      const editBtn =
        document.querySelector(`.block.${name} .shortcut-sidebar-dropdown-toggle`) ||
        document.querySelector(`.block.${name} .edit-link`);
      editBtn.click();
    }, DEBOUNCE_DROPDOWN_DELAY);
    return false;
  }

  async copyBranchName() {
    const button = document.querySelector('.js-source-branch-copy');
    const branchName = button?.dataset.clipboardText;

    if (branchName) {
      this.branchInMemoryButton.dataset.clipboardText = branchName;

      this.branchInMemoryButton.dispatchEvent(new CustomEvent('click'));
    }
  }

  async copyIssuableRef() {
    const refButton = document.querySelector('.js-copy-reference');
    const copiedRef = refButton?.dataset.clipboardText;

    if (copiedRef) {
      this.refInMemoryButton.dataset.clipboardText = copiedRef;

      this.refInMemoryButton.dispatchEvent(new CustomEvent('click'));
    }
  }
}
