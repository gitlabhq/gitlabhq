import Wikis from '~/pages/projects/wikis/wikis';
import { setHTMLFixture } from './helpers/fixtures';

describe('Wikis', () => {
  describe('setting the commit message when the title changes', () => {
    let wikis;
    let titleInput;
    let messageInput;
    const CREATE = true;
    const UPDATE = false;

    const editFormHtmlFixture = newPage =>
      `<form class="wiki-form ${newPage ? 'js-new-wiki-page' : ''}">
        <input type="text" id="wiki_page_title" value="My title" />
        <input type="text" id="wiki_page_message" />
      </form>`;

    const init = newPage => {
      setHTMLFixture(editFormHtmlFixture(newPage));
      titleInput = document.getElementById('wiki_page_title');
      messageInput = document.getElementById('wiki_page_message');
      wikis = new Wikis();
    };

    describe('when the wiki page is being created', () => {
      beforeEach(() => init(CREATE));

      it('binds an event listener to the title input', () => {
        wikis.handleWikiTitleChange = jest.fn();

        titleInput.dispatchEvent(new Event('keyup'));

        expect(wikis.handleWikiTitleChange).toHaveBeenCalled();
      });

      it('sets the commit message when title changes', () => {
        titleInput.value = 'My title';
        messageInput.value = '';

        titleInput.dispatchEvent(new Event('keyup'));

        expect(messageInput.value).toEqual('Create My title');
      });

      it('replaces hyphens with spaces', () => {
        titleInput.value = 'my-hyphenated-title';
        titleInput.dispatchEvent(new Event('keyup'));

        expect(messageInput.value).toEqual('Create my hyphenated title');
      });
    });

    describe('when the wiki page is being updated', () => {
      beforeEach(() => init(UPDATE));

      it('sets the commit message when title changes, prefixing with "Update"', () => {
        titleInput.value = 'My title';
        messageInput.value = '';

        titleInput.dispatchEvent(new Event('keyup'));

        expect(messageInput.value).toEqual('Update My title');
      });
    });
  });
});
