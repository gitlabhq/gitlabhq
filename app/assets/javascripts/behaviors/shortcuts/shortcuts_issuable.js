import $ from 'jquery';
import Mousetrap from 'mousetrap';
import { clickCopyToClipboardButton } from '~/behaviors/copy_to_clipboard';
import { getSelectedFragment } from '~/lib/utils/common_utils';
import { isElementVisible } from '~/lib/utils/dom_utils';
import Sidebar from '../../right_sidebar';
import { CopyAsGFM } from '../markdown/copy_as_gfm';
import {
  keysFor,
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

    Mousetrap.bind(keysFor(ISSUE_MR_CHANGE_ASSIGNEE), () =>
      ShortcutsIssuable.openSidebarDropdown('assignee'),
    );
    Mousetrap.bind(keysFor(ISSUE_MR_CHANGE_MILESTONE), () =>
      ShortcutsIssuable.openSidebarDropdown('milestone'),
    );
    Mousetrap.bind(keysFor(ISSUABLE_CHANGE_LABEL), () =>
      ShortcutsIssuable.openSidebarDropdown('labels'),
    );
    Mousetrap.bind(keysFor(ISSUABLE_COMMENT_OR_REPLY), ShortcutsIssuable.replyWithSelectedText);
    Mousetrap.bind(keysFor(ISSUABLE_EDIT_DESCRIPTION), ShortcutsIssuable.editIssue);
    Mousetrap.bind(keysFor(MR_COPY_SOURCE_BRANCH_NAME), ShortcutsIssuable.copyBranchName);
  }

  static replyWithSelectedText() {
    const $replyField = $('.js-main-target-form .js-vue-comment-form');

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
    return false;
  }

  static copyBranchName() {
    // There are two buttons - one that is shown when the sidebar
    // is expanded, and one that is shown when it's collapsed.
    const allCopyBtns = Array.from(document.querySelectorAll('.js-sidebar-source-branch button'));

    // Select whichever button is currently visible so that
    // the "Copied" tooltip is shown when a click is simulated.
    const visibleBtn = allCopyBtns.find(isElementVisible);

    if (visibleBtn) {
      clickCopyToClipboardButton(visibleBtn);
    }
  }
}
