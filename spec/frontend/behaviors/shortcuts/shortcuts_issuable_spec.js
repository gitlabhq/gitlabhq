import $ from 'jquery';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { mount } from '@vue/test-utils';
import htmlSnippetsShow from 'test_fixtures/snippets/show.html';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import initCopyAsGFM, { CopyAsGFM } from '~/behaviors/markdown/copy_as_gfm';
import ShortcutsIssuable from '~/behaviors/shortcuts/shortcuts_issuable';
import { getSelectedFragment } from '~/lib/utils/common_utils';
import { useFakeRequestAnimationFrame } from 'helpers/fake_request_animation_frame';
import NoteableDiscussion from '~/notes/components/noteable_discussion.vue';
import notesStore from '~/notes/stores';
import { discussionMock, noteableDataMock, notesDataMock } from 'jest/notes/mock_data';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/lib/utils/common_utils', () => ({
  ...jest.requireActual('~/lib/utils/common_utils'),
  getSelectedFragment: jest.fn().mockName('getSelectedFragment'),
}));

jest.mock('~/emoji');
jest.mock('~/lib/graphql');

Vue.use(Vuex);

describe('ShortcutsIssuable', () => {
  useFakeRequestAnimationFrame();

  beforeAll(() => {
    initCopyAsGFM();

    // Fake call to nodeToGfm so the import of lazy bundle happened
    return CopyAsGFM.nodeToGFM(document.createElement('div'));
  });

  describe('replyWithSelectedText', () => {
    const FORM_SELECTOR = '.js-main-target-form .js-gfm-input';

    beforeEach(() => {
      setHTMLFixture(htmlSnippetsShow);
      $('body').append(
        `<div class="js-main-target-form">
          <textarea class="js-gfm-input"></textarea>
        </div>`,
      );
      document.querySelector('.js-new-note-form').classList.add('js-main-target-form');
    });

    afterEach(() => {
      $(FORM_SELECTOR).remove();

      resetHTMLFixture();
    });

    // Stub getSelectedFragment to return a node with the provided HTML.
    const stubSelection = (html, invalidNode) => {
      getSelectedFragment.mockImplementation(() => {
        const documentFragment = document.createDocumentFragment();
        const node = document.createElement('div');

        node.innerHTML = html;
        if (!invalidNode) node.className = 'md';

        documentFragment.appendChild(node);
        return documentFragment;
      });
    };

    it('sets up commands on instantiation', () => {
      const mockShortcutsInstance = { addAll: jest.fn() };

      // eslint-disable-next-line no-new
      new ShortcutsIssuable(mockShortcutsInstance);

      expect(mockShortcutsInstance.addAll).toHaveBeenCalled();
    });

    describe('with empty selection', () => {
      it('does not return an error', () => {
        ShortcutsIssuable.replyWithSelectedText(true);

        expect($(FORM_SELECTOR).val()).toBe('');
      });

      it('triggers `focus`', async () => {
        const spy = jest.spyOn(document.querySelector(FORM_SELECTOR), 'focus');
        await ShortcutsIssuable.replyWithSelectedText(true);

        expect(spy).toHaveBeenCalled();
      });
    });

    describe('with any selection', () => {
      beforeEach(() => {
        stubSelection('<p>Selected text.</p>');
      });

      it('leaves existing input intact', async () => {
        $(FORM_SELECTOR).val('This text was already here.');

        expect($(FORM_SELECTOR).val()).toBe('This text was already here.');

        await ShortcutsIssuable.replyWithSelectedText(true);

        expect($(FORM_SELECTOR).val()).toBe('This text was already here.\n\n> Selected text.\n\n');
      });

      it('triggers `input`', async () => {
        let triggered = false;
        $(FORM_SELECTOR).on('input', () => {
          triggered = true;
        });

        await ShortcutsIssuable.replyWithSelectedText(true);
        expect(triggered).toBe(true);
      });

      it('triggers `focus`', async () => {
        const spy = jest.spyOn(document.querySelector(FORM_SELECTOR), 'focus');
        await ShortcutsIssuable.replyWithSelectedText(true);
        expect(spy).toHaveBeenCalled();
      });
    });

    describe('with a one-line selection', () => {
      it('quotes the selection', async () => {
        stubSelection('<p>This text has been selected.</p>');
        await ShortcutsIssuable.replyWithSelectedText(true);
        expect($(FORM_SELECTOR).val()).toBe('> This text has been selected.\n\n');
      });
    });

    describe('with a multi-line selection', () => {
      it('quotes the selected lines as a group', async () => {
        stubSelection(
          '<p>Selected line one.</p>\n<p>Selected line two.</p>\n<p>Selected line three.</p>',
        );
        await ShortcutsIssuable.replyWithSelectedText(true);
        expect($(FORM_SELECTOR).val()).toBe(
          '> Selected line one.\n>\n> Selected line two.\n>\n> Selected line three.\n\n',
        );
      });
    });

    describe('with an invalid selection', () => {
      beforeEach(() => {
        stubSelection('<p>Selected text.</p>', true);
      });

      it('does not add anything to the input', async () => {
        await ShortcutsIssuable.replyWithSelectedText(true);
        expect($(FORM_SELECTOR).val()).toBe('');
      });

      it('triggers `focus`', async () => {
        const spy = jest.spyOn(document.querySelector(FORM_SELECTOR), 'focus');
        await ShortcutsIssuable.replyWithSelectedText(true);
        expect(spy).toHaveBeenCalled();
      });
    });

    describe('with a semi-valid selection', () => {
      beforeEach(() => {
        stubSelection('<div class="md">Selected text.</div><p>Invalid selected text.</p>', true);
      });

      it('only adds the valid part to the input', async () => {
        await ShortcutsIssuable.replyWithSelectedText(true);
        expect($(FORM_SELECTOR).val()).toBe('> Selected text.\n\n');
      });

      it('triggers `focus`', async () => {
        const spy = jest.spyOn(document.querySelector(FORM_SELECTOR), 'focus');
        await ShortcutsIssuable.replyWithSelectedText(true);
        expect(spy).toHaveBeenCalled();
      });

      it('triggers `input`', async () => {
        let triggered = false;
        $(FORM_SELECTOR).on('input', () => {
          triggered = true;
        });

        await ShortcutsIssuable.replyWithSelectedText(true);
        expect(triggered).toBe(true);
      });
    });

    describe('with a selection in a valid block', () => {
      beforeEach(() => {
        getSelectedFragment.mockImplementation(() => {
          const documentFragment = document.createDocumentFragment();
          const node = document.createElement('div');
          const originalNode = document.createElement('body');
          originalNode.innerHTML = `<div class="issue">
            <div class="otherElem">Text...</div>
            <div class="md"><p><em>Selected text.</em></p></div>
          </div>`;
          documentFragment.originalNodes = [originalNode.querySelector('em')];

          node.innerHTML = '<em>Selected text.</em>';

          documentFragment.appendChild(node);

          return documentFragment;
        });
      });

      it('adds the quoted selection to the input', async () => {
        await ShortcutsIssuable.replyWithSelectedText(true);
        expect($(FORM_SELECTOR).val()).toBe('> _Selected text._\n\n');
      });

      it('triggers `focus`', async () => {
        const spy = jest.spyOn(document.querySelector(FORM_SELECTOR), 'focus');
        await ShortcutsIssuable.replyWithSelectedText(true);
        expect(spy).toHaveBeenCalled();
      });

      it('triggers `input`', async () => {
        let triggered = false;
        $(FORM_SELECTOR).on('input', () => {
          triggered = true;
        });

        await ShortcutsIssuable.replyWithSelectedText(true);
        expect(triggered).toBe(true);
      });
    });

    describe('with a selection in an invalid block', () => {
      beforeEach(() => {
        getSelectedFragment.mockImplementation(() => {
          const documentFragment = document.createDocumentFragment();
          const node = document.createElement('div');
          const originalNode = document.createElement('body');
          originalNode.innerHTML = `<div class="issue">
            <div class="otherElem"><div><b>Selected text.</b></div></div>
            <div class="md"><p><em>Valid text</em></p></div>
          </div>`;
          documentFragment.originalNodes = [originalNode.querySelector('b')];

          node.innerHTML = '<b>Selected text.</b>';

          documentFragment.appendChild(node);

          return documentFragment;
        });
      });

      it('does not add anything to the input', async () => {
        await ShortcutsIssuable.replyWithSelectedText(true);
        expect($(FORM_SELECTOR).val()).toBe('');
      });

      it('triggers `focus`', async () => {
        const spy = jest.spyOn(document.querySelector(FORM_SELECTOR), 'focus');
        await ShortcutsIssuable.replyWithSelectedText(true);
        expect(spy).toHaveBeenCalled();
      });
    });

    describe('with a valid selection with no text content', () => {
      it('returns the proper markdown', async () => {
        stubSelection('<img src="https://gitlab.com/logo.png" alt="logo" />');
        await ShortcutsIssuable.replyWithSelectedText(true);
        expect($(FORM_SELECTOR).val()).toBe('> ![logo](https://gitlab.com/logo.png)\n\n');
      });
    });

    describe('when thread text is selected', () => {
      let wrapper;

      beforeEach(() => {
        global.requestAnimationFrame = async (cb) => {
          await waitForPromises();
          cb();
        };

        // clear draft messages after the first test
        window.localStorage.clear();

        stubSelection(
          '<p>Selected line one.</p>\n<p>Selected line two.</p>\n<p>Selected line three.</p>',
        );

        const store = notesStore();
        store.dispatch('setNoteableData', noteableDataMock);
        store.dispatch('setNotesData', notesDataMock);

        wrapper = mount(NoteableDiscussion, {
          attachTo: document.body,
          store,
          propsData: {
            discussion: discussionMock,
          },
          stubs: {
            EmojiPicker: true,
          },
        });

        jest.spyOn(window, 'getSelection').mockReturnValue({
          rangeCount: 1,
          getRangeAt() {
            return {
              startContainer: wrapper.element.querySelector('p'),
            };
          },
        });
      });

      it('expands collapsed reply placeholder with quote text', async () => {
        await ShortcutsIssuable.replyWithSelectedText(true);
        expect(wrapper.element.querySelector('textarea.js-gfm-input').value).toBe(
          '> Selected line one.\n>\n> Selected line two.\n>\n> Selected line three.\n\n',
        );
      });

      it('inserts quote text into expanded reply form', async () => {
        wrapper.element
          .querySelector('.js-discussion-reply-field-placeholder')
          .dispatchEvent(new Event('focus'));
        await waitForPromises();
        await ShortcutsIssuable.replyWithSelectedText(true);
        expect(wrapper.element.querySelector('textarea.js-gfm-input').value).toBe(
          '> Selected line one.\n>\n> Selected line two.\n>\n> Selected line three.\n\n',
        );
      });
    });
  });
});
