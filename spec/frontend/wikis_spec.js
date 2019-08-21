import Wikis from '~/pages/projects/wikis/wikis';
import { setHTMLFixture } from './helpers/fixtures';

describe('Wikis', () => {
  describe('setting the commit message when the title changes', () => {
    const editFormHtmlFixture = args => `<form class="wiki-form ${
      args.newPage ? 'js-new-wiki-page' : ''
    }">
        <input type="text" id="wiki_title" value="My title" />
        <input type="text" id="wiki_message" />
      </form>`;

    let wikis;
    let titleInput;
    let messageInput;

    describe('when the wiki page is being created', () => {
      const formHtmlFixture = editFormHtmlFixture({ newPage: true });

      beforeEach(() => {
        setHTMLFixture(formHtmlFixture);

        titleInput = document.getElementById('wiki_title');
        messageInput = document.getElementById('wiki_message');
        wikis = new Wikis();
      });

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
      const formHtmlFixture = editFormHtmlFixture({ newPage: false });

      beforeEach(() => {
        setHTMLFixture(formHtmlFixture);

        titleInput = document.getElementById('wiki_title');
        messageInput = document.getElementById('wiki_message');
        wikis = new Wikis();
      });

      it('sets the commit message when title changes, prefixing with "Update"', () => {
        titleInput.value = 'My title';
        messageInput.value = '';

        titleInput.dispatchEvent(new Event('keyup'));

        expect(messageInput.value).toEqual('Update My title');
      });
    });
  });
});
