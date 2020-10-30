import imageRenderer from '~/static_site_editor/services/renderers/render_image';
import { mounts, project } from '../../mock_data';

describe('rich_content_editor/renderers/render_image', () => {
  let renderer;

  beforeEach(() => {
    renderer = imageRenderer.build(mounts, project);
  });

  describe('build', () => {
    it('builds a renderer object containing `canRender` and `render` functions', () => {
      expect(renderer).toHaveProperty('canRender', expect.any(Function));
      expect(renderer).toHaveProperty('render', expect.any(Function));
    });
  });

  describe('canRender', () => {
    it.each`
      input                    | result
      ${{ type: 'image' }}     | ${true}
      ${{ type: 'text' }}      | ${false}
      ${{ type: 'htmlBlock' }} | ${false}
    `('returns $result when input is $input', ({ input, result }) => {
      expect(renderer.canRender(input)).toBe(result);
    });
  });

  describe('render', () => {
    let context;
    let result;
    const skipChildren = jest.fn();

    beforeEach(() => {
      const node = {
        destination: '/some/path/image.png',
        firstChild: {
          type: 'img',
          literal: 'Some Image',
        },
      };

      context = { skipChildren };
      result = renderer.render(node, context);
    });

    it('invokes `skipChildren`', () => {
      expect(skipChildren).toHaveBeenCalled();
    });

    it('returns an image', () => {
      expect(result).toEqual({
        type: 'openTag',
        tagName: 'img',
        selfClose: true,
        attributes: {
          src: '/some/path/image.png',
          alt: 'Some Image',
        },
      });
    });
  });
});
