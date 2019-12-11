import snippetEmbed from '~/snippet/snippet_embed';
import { loadHTMLFixture } from './helpers/fixtures';

describe('Snippets', () => {
  let embedBtn;
  let snippetUrlArea;
  let shareBtn;
  let scriptTag;

  const snippetUrl = 'http://test.host/snippets/1';

  beforeEach(() => {
    loadHTMLFixture('snippets/show.html');

    embedBtn = document.querySelector('.js-embed-btn');
    snippetUrlArea = document.querySelector('.js-snippet-url-area');
    shareBtn = document.querySelector('.js-share-btn');
  });

  it('selects the fields content when it is clicked', () => {
    jest.spyOn(snippetUrlArea, 'select');
    snippetEmbed();

    expect(snippetUrlArea.select).not.toHaveBeenCalled();
    snippetUrlArea.dispatchEvent(new Event('click'));
    expect(snippetUrlArea.select).toHaveBeenCalled();
  });

  describe('when the snippet url does not include params', () => {
    beforeEach(() => {
      snippetEmbed();

      scriptTag = `<script src="${snippetUrl}.js"></script>`;
    });

    it('shows the script tag as default', () => {
      expect(snippetUrlArea.value).toEqual(scriptTag);
    });

    it('sets the proper url depending on the button clicked', () => {
      shareBtn.dispatchEvent(new Event('click'));
      expect(snippetUrlArea.value).toEqual(snippetUrl);

      embedBtn.dispatchEvent(new Event('click'));
      expect(snippetUrlArea.value).toEqual(scriptTag);
    });
  });

  describe('when the snippet url includes params', () => {
    beforeEach(() => {
      scriptTag = `<script src="${snippetUrl}.js?foo=bar"></script>`;
      snippetUrlArea.value = scriptTag;
      snippetUrlArea.dataset.url = `${snippetUrl}?foo=bar`;

      snippetEmbed();
    });

    it('shows the script tag as default', () => {
      expect(snippetUrlArea.value).toEqual(scriptTag);
    });

    it('sets the proper url depending on the button clicked', () => {
      shareBtn.dispatchEvent(new Event('click'));
      expect(snippetUrlArea.value).toEqual(`${snippetUrl}?foo=bar`);

      embedBtn.dispatchEvent(new Event('click'));
      expect(snippetUrlArea.value).toEqual(scriptTag);
    });
  });
});
