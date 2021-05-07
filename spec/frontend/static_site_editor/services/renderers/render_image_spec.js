import imageRenderer from '~/static_site_editor/services/renderers/render_image';
import { mounts, project, branch, baseUrl } from '../../mock_data';

describe('rich_content_editor/renderers/render_image', () => {
  let renderer;
  let imageRepository;

  beforeEach(() => {
    renderer = imageRenderer.build(mounts, project, branch, baseUrl, imageRepository);
    imageRepository = { get: () => null };
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
    let skipChildren;
    let context;
    let node;

    beforeEach(() => {
      skipChildren = jest.fn();
      context = { skipChildren };
      node = {
        firstChild: {
          type: 'img',
          literal: 'Some Image',
        },
      };
    });

    it.each`
      destination                                      | isAbsolute | src
      ${'http://test.host/absolute/path/to/image.png'} | ${true}    | ${'http://test.host/absolute/path/to/image.png'}
      ${'/relative/path/to/image.png'}                 | ${false}   | ${'http://test.host/user1/project1/-/raw/main/default/source/relative/path/to/image.png'}
      ${'/target/image.png'}                           | ${false}   | ${'http://test.host/user1/project1/-/raw/main/source/with/target/image.png'}
      ${'relative/to/current/image.png'}               | ${false}   | ${'http://test.host/user1/project1/-/raw/main/relative/to/current/image.png'}
      ${'./relative/to/current/image.png'}             | ${false}   | ${'http://test.host/user1/project1/-/raw/main/./relative/to/current/image.png'}
      ${'../relative/to/current/image.png'}            | ${false}   | ${'http://test.host/user1/project1/-/raw/main/../relative/to/current/image.png'}
    `('returns an image with the correct attributes', ({ destination, isAbsolute, src }) => {
      node.destination = destination;

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

    it('renders an image if a cached image is found in the repository, use the base64 content as the source', () => {
      const imageContent = 'some-content';
      const originalSrc = 'path/to/image.png';

      imageRepository.get = () => imageContent;
      renderer = imageRenderer.build(mounts, project, branch, baseUrl, imageRepository);
      node.destination = originalSrc;

      const result = renderer.render(node, context);

      expect(result).toEqual({
        type: 'openTag',
        tagName: 'img',
        selfClose: true,
        attributes: {
          'data-original-src': originalSrc,
          src: `data:image;base64,${imageContent}`,
          alt: 'Some Image',
        },
      });
    });
  });
});
