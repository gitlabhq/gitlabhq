import buildCustomHTMLRenderer from '~/static_site_editor/rich_content_editor/services/build_custom_renderer';

describe('Build Custom Renderer Service', () => {
  describe('buildCustomHTMLRenderer', () => {
    it('should return an object with the default renderer functions when lacking arguments', () => {
      expect(buildCustomHTMLRenderer()).toEqual(
        expect.objectContaining({
          htmlBlock: expect.any(Function),
          htmlInline: expect.any(Function),
          heading: expect.any(Function),
          item: expect.any(Function),
          paragraph: expect.any(Function),
          text: expect.any(Function),
          softbreak: expect.any(Function),
        }),
      );
    });

    it('should return an object with both custom and default renderer functions when passed customRenderers', () => {
      const mockHtmlCustomRenderer = jest.fn();
      const customRenderers = {
        html: [mockHtmlCustomRenderer],
      };

      expect(buildCustomHTMLRenderer(customRenderers)).toEqual(
        expect.objectContaining({
          html: expect.any(Function),
        }),
      );
    });
  });
});
