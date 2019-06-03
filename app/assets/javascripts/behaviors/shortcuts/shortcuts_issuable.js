import $ from 'jquery';
import Mousetrap from 'mousetrap';
import Sidebar from '../../right_sidebar';
import Shortcuts from './shortcuts';
import { CopyAsGFM } from '../markdown/copy_as_gfm';
import { getSelectedFragment } from '~/lib/utils/common_utils';

export default class ShortcutsIssuable extends Shortcuts {
  constructor(isMergeRequest) {
    super();

    Mousetrap.bind('a', () => ShortcutsIssuable.openSidebarDropdown('assignee'));
    Mousetrap.bind('m', () => ShortcutsIssuable.openSidebarDropdown('milestone'));
    Mousetrap.bind('l', () => ShortcutsIssuable.openSidebarDropdown('labels'));
    Mousetrap.bind('r', ShortcutsIssuable.replyWithSelectedText);
    Mousetrap.bind('e', ShortcutsIssuable.editIssue);

    if (isMergeRequest) {
      this.enabledHelp.push('.hidden-shortcut.merge_requests');
    } else {
      this.enabledHelp.push('.hidden-shortcut.issues');
    }
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
        documentFragment.originalNodes.forEach(e => {
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
      .then(text => {
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
}
