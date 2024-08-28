import $ from 'jquery';
import ClipboardJS from 'clipboard';
import { getSelectedFragment } from '~/lib/utils/common_utils';
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
  ISSUABLE_COPY_REF,
} from './keybindings';

const nextFrame = () =>
  new Promise((resolve) => {
    requestAnimationFrame(resolve);
  });

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
      [ISSUABLE_COMMENT_OR_REPLY, ShortcutsIssuable.replyWithSelectedText],
      [ISSUABLE_EDIT_DESCRIPTION, ShortcutsIssuable.editIssue],
      [MR_COPY_SOURCE_BRANCH_NAME, () => this.copyBranchName()],
      [ISSUABLE_COPY_REF, () => this.copyIssuableRef()],
    ]);
  }

  static async replyWithSelectedText() {
    const documentFragment = getSelectedFragment(document.querySelector('#content-body'));
    const $replyField = await ShortcutsIssuable.getCurrentReplyField();

    if (!$replyField.length || $replyField.is(':hidden') /* Other tab selected in MR */) {
      return false;
    }

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
    const text = await CopyAsGFM.nodeToGFM(blockquoteEl);

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
  }

  static async getCurrentReplyField() {
    const defaultReplyField = $('.js-main-target-form .js-gfm-input');
    const selection = window.getSelection();

    // prevent hotkey input from going directly into the textarea
    await nextFrame();

    if (selection.rangeCount <= 0) return defaultReplyField;

    const range = selection.getRangeAt(0);
    const selectedNode = range.startContainer;
    const discussionContainer =
      selectedNode.nodeType === Node.TEXT_NODE
        ? $(selectedNode.parentNode.closest('.js-discussion-container'))
        : $(selectedNode.closest('.js-discussion-container'));

    if (discussionContainer.length === 0) return defaultReplyField;

    const replyField = discussionContainer.find('.js-gfm-input');
    if (replyField.length !== 0) return replyField;

    const placeholder = discussionContainer.find('.js-discussion-reply-field-placeholder');
    if (placeholder.length === 0) return defaultReplyField;

    placeholder.get(0).dispatchEvent(new Event('focus'));
    // wait for Vue to re-render
    await nextFrame();
    return discussionContainer.find('.js-gfm-input');
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
