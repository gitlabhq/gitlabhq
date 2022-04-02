import { render } from '~/lib/gfm';

describe('gfm', () => {
  describe('render', () => {
    it('processes Commonmark and provides an ast to the renderer function', async () => {
      let result;

      await render({
        markdown: 'This is text',
        renderer: (tree) => {
          result = tree;
        },
      });

      expect(result.type).toBe('root');
    });

    it('transforms raw HTML into individual nodes in the AST', async () => {
      let result;

      await render({
        markdown: '<strong>This is bold text</strong>',
        renderer: (tree) => {
          result = tree;
        },
      });

      expect(result.children[0].children[0]).toMatchObject({
        type: 'element',
        tagName: 'strong',
        properties: {},
      });
    });

    it('returns the result of executing the renderer function', async () => {
      const result = await render({
        markdown: '<strong>This is bold text</strong>',
        renderer: () => {
          return 'rendered tree';
        },
      });

      expect(result).toBe('rendered tree');
    });
  });
});
