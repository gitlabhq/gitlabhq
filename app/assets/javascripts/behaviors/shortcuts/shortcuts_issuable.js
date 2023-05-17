import $ from 'jquery';
import ClipboardJS from 'clipboard';
import { getSelectedFragment } from '~/lib/utils/common_utils';
import { isElementVisible } from '~/lib/utils/dom_utils';
import { DEBOUNCE_DROPDOWN_DELAY } from '~/sidebar/components/labels/labels_select_widget/constants';
import toast from '~/vue_shared/plugins/global_toast';
import { s__ } from '~/locale';
import Sidebar from '~/right_sidebar';
import { CopyAsGFM } from '../markdown/copy_as_gfm';
import {
  ISSUE_MR_CHANGE_ASSIGNEE,
  ISSUE_MR_CHANGE_MILESTONE,
  ISSUABLE_CHANGE_LABEL,
  ISSUABLE_COMMENT_OR_REPLY,
  ISSUABLE_EDIT_DESCRIPTION,
  MR_COPY_SOURCE_BRANCH_NAME,
} from './keybindings';
import Shortcuts from './shortcuts';

export default class ShortcutsIssuable extends Shortcuts {
  constructor() {
    super();

    this.inMemoryButton = document.createElement('button');
    this.clipboardInstance = new ClipboardJS(this.inMemoryButton);
    this.clipboardInstance.on('success', () => {
      toast(s__('GlobalShortcuts|Copied source branch name to clipboard.'));
    });
    this.clipboardInstance.on('error', () => {
      toast(s__('GlobalShortcuts|Unable to copy the source branch name at this time.'));
    });

    this.bindCommands([
      [ISSUE_MR_CHANGE_ASSIGNEE, () => ShortcutsIssuable.openSidebarDropdown('assignee')],
      [ISSUE_MR_CHANGE_MILESTONE, () => ShortcutsIssuable.openSidebarDropdown('milestone')],
      [ISSUABLE_CHANGE_LABEL, () => ShortcutsIssuable.openSidebarDropdown('labels')],
      [ISSUABLE_COMMENT_OR_REPLY, ShortcutsIssuable.replyWithSelectedText],
      [ISSUABLE_EDIT_DESCRIPTION, ShortcutsIssuable.editIssue],
      [MR_COPY_SOURCE_BRANCH_NAME, () => this.copyBranchName()],
    ]);

    /**
     * We're attaching a global focus event listener on document for
     * every markdown input field.
     */
    $(document).on(
      'focus',
      '.js-vue-markdown-field .js-gfm-input',
      ShortcutsIssuable.handleMarkdownFieldFocus,
    );
  }

  /**
   * This event handler preserves last focused markdown input field.
   * @param {Object} event
   */
  static handleMarkdownFieldFocus({ currentTarget }) {
    ShortcutsIssuable.$lastFocusedReplyField = $(currentTarget);
  }

  static replyWithSelectedText() {
    let $replyField = $('.js-main-target-form .js-vue-comment-form');

    // Ensure that markdown input is still present in the DOM
    // otherwise fall back to main comment input field.
    if (
      ShortcutsIssuable.$lastFocusedReplyField &&
      isElementVisible(ShortcutsIssuable.$lastFocusedReplyField?.get(0))
    ) {
      $replyField = ShortcutsIssuable.$lastFocusedReplyField;
    }

    if (!$replyField.length || $replyField.is(':hidden') /* Other tab selected in MR */) {
      return false;
    }

    const documentFragment = getSelectedFragment(document.querySelector('#content-body'));

    if (!documentFragment) {
      $replyField.focus();
      return false;
    }

    // Sanity check: Make sure the selected text comes from a discussion : it can either contain a message...
    let foundMessage = Boolean(documentFragment.querySelector('.md'));

    // ... Or come from a message
    if (!foundMessage) {
      if (documentFragment.originalNodes) {
        documentFragment.originalNodes.forEach((e) => {
          let node = e;
          do {
            // Text nodes don't define the `matches` method
            if (node.matches && node.matches('.md')) {
              foundMessage = true;
            }
            node = node.parentNode;
          } while (node && !foundMessage);
        });
      }

      // If there is no message, just select the reply field
      if (!foundMessage) {
        $replyField.focus();
        return false;
      }
    }

    const el = CopyAsGFM.transformGFMSelection(documentFragment.cloneNode(true));
    const blockquoteEl = document.createElement('blockquote');
    blockquoteEl.appendChild(el);
    CopyAsGFM.nodeToGFM(blockquoteEl)
      .then((text) => {
        if (text.trim() === '') {
          return false;
        }

        // If replyField already has some content, add a newline before our quote
        const separator = ($replyField.val().trim() !== '' && '\n\n') || '';
        $replyField
          .val((a, current) => `${current}${separator}${text}\n\n`)
          .trigger('input')
          .trigger('change');

        // Trigger autosize
        const event = document.createEvent('Event');
        event.initEvent('autosize:update', true, false);
        $replyField.get(0).dispatchEvent(event);

        // Focus the input field
        $replyField.focus();

        return false;
      })
      .catch(() => {});

    return false;
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
      this.inMemoryButton.dataset.clipboardText = branchName;

      this.inMemoryButton.dispatchEvent(new CustomEvent('click'));
    }
  }
}
