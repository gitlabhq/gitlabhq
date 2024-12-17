import ClipboardJS from 'clipboard';
import toast from '~/vue_shared/plugins/global_toast';
import { getSelectedFragment } from '~/lib/utils/common_utils';
import { isElementVisible } from '~/lib/utils/dom_utils';
import { s__ } from '~/locale';
import { DEBOUNCE_DROPDOWN_DELAY } from '~/sidebar/components/labels/labels_select_widget/constants';
import { CopyAsGFM } from '../markdown/copy_as_gfm';
import {
  ISSUE_MR_CHANGE_ASSIGNEE,
  ISSUE_MR_CHANGE_MILESTONE,
  ISSUABLE_CHANGE_LABEL,
  ISSUABLE_EDIT_DESCRIPTION,
  ISSUABLE_COPY_REF,
  ISSUABLE_COMMENT_OR_REPLY,
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
      [ISSUABLE_COPY_REF, () => this.copyReference()],
      [ISSUABLE_COMMENT_OR_REPLY, ShortcutsWorkItem.replyWithSelectedText],
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
        document.querySelector(`.gl-drawer ${shortcutSelector}`) ||
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
      document.querySelector(`.gl-drawer ${editDescriptionSelector}`) ||
      document.querySelector(`.modal ${editDescriptionSelector}`) ||
      document.querySelector(editDescriptionSelector);

    editButton?.click();

    return false;
  }

  async copyReference() {
    const refSelector = '.shortcut-copy-reference';
    const refButton =
      document.querySelector(`.gl-drawer ${refSelector}`) ||
      document.querySelector(`.modal ${refSelector}`) ||
      document.querySelector(refSelector);
    const copiedRef = refButton?.dataset.clipboardText;

    if (copiedRef) {
      this.refInMemoryButton.dataset.clipboardText = copiedRef;

      this.refInMemoryButton.dispatchEvent(new CustomEvent('click'));
    }
  }

  static replyWithSelectedText() {
    const gfmSelector = '.js-vue-markdown-field .js-gfm-input';
    let replyField =
      document.querySelector(`.gl-drawer ${gfmSelector}`) ||
      document.querySelector(`.modal ${gfmSelector}`) ||
      document.querySelector(gfmSelector);

    // Ensure that markdown input is still present in the DOM
    // otherwise fall back to main comment input field.
    if (
      ShortcutsWorkItem.lastFocusedReplyField &&
      isElementVisible(ShortcutsWorkItem.lastFocusedReplyField)
    ) {
      replyField = ShortcutsWorkItem.lastFocusedReplyField;
    }

    if (!replyField || !isElementVisible(replyField)) {
      return false;
    }

    const documentFragment = getSelectedFragment(document.querySelector('#content-body'));

    if (!documentFragment) {
      replyField.focus();
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
        replyField.focus();
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
        const separator = (replyField.value.trim() !== '' && '\n\n') || '';
        replyField.value = `${replyField.value}${separator}${text}\n\n`;

        // Trigger autosize
        const event = document.createEvent('Event');
        event.initEvent('autosize:update', true, false);
        replyField.dispatchEvent(event);

        // Focus the input field
        replyField.focus();

        return false;
      })
      .catch(() => {});

    return false;
  }
}
