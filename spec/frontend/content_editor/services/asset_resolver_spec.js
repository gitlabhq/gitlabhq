import createAssetResolver from '~/content_editor/services/asset_resolver';

describe('content_editor/services/asset_resolver', () => {
  let renderMarkdown;
  let assetResolver;

  beforeEach(() => {
    renderMarkdown = jest.fn();
    assetResolver = createAssetResolver({ renderMarkdown });
  });

  describe('resolveUrl', () => {
    it('resolves a canonical url to an absolute url', async () => {
      renderMarkdown.mockResolvedValue(
        '<p><a href="/group1/project1/-/wikis/test-file.png" data-canonical-src="test-file.png">link</a></p>',
      );

      expect(await assetResolver.resolveUrl('test-file.png')).toBe(
        '/group1/project1/-/wikis/test-file.png',
      );
    });
  });

  describe('renderDiagram', () => {
    it('resolves a diagram code to a url containing the diagram image', async () => {
      renderMarkdown.mockResolvedValue(
        '<p><img data-diagram="nomnoml" src="url/to/some/diagram"></p>',
      );

      expect(await assetResolver.renderDiagram('test')).toBe('url/to/some/diagram');
    });
  });
});
