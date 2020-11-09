import imageRenderer from '~/static_site_editor/services/renderers/render_image';
import { mounts, project, branch, baseUrl } from '../../mock_data';

describe('rich_content_editor/renderers/render_image', () => {
  let renderer;

  beforeEach(() => {
    renderer = imageRenderer.build(mounts, project, branch, baseUrl);
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
    it.each`
      destination                                      | isAbsolute | src
      ${'http://test.host/absolute/path/to/image.png'} | ${true}    | ${'http://test.host/absolute/path/to/image.png'}
      ${'/relative/path/to/image.png'}                 | ${false}   | ${'http://test.host/user1/project1/-/raw/master/default/source/relative/path/to/image.png'}
      ${'/target/image.png'}                           | ${false}   | ${'http://test.host/user1/project1/-/raw/master/source/with/target/image.png'}
      ${'relative/to/current/image.png'}               | ${false}   | ${'http://test.host/user1/project1/-/raw/master/relative/to/current/image.png'}
      ${'./relative/to/current/image.png'}             | ${false}   | ${'http://test.host/user1/project1/-/raw/master/./relative/to/current/image.png'}
      ${'../relative/to/current/image.png'}            | ${false}   | ${'http://test.host/user1/project1/-/raw/master/../relative/to/current/image.png'}
    `('returns an image with the correct attributes', ({ destination, isAbsolute, src }) => {
      const skipChildren = jest.fn();
      const context = { skipChildren };
      const node = {
        destination,
        firstChild: {
          type: 'img',
          literal: 'Some Image',
        },
      };
      const result = renderer.render(node, context);

      expect(result).toEqual({
        type: 'openTag',
        tagName: 'img',
        selfClose: true,
        attributes: {
          'data-original-src': !isAbsolute ? destination : '',
          src,
          alt: 'Some Image',
        },
      });

      expect(skipChildren).toHaveBeenCalled();
    });
  });
});
