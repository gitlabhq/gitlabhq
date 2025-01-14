import { serialize, serializeWithOptions, builders, sourceTag } from '../../serialization_utils';

const { paragraph, image } = builders;

it('correctly serializes an image', () => {
  expect(serialize(paragraph(image({ src: 'img.jpg', alt: 'foo bar' })))).toBe(
    '![foo bar](img.jpg)',
  );
});

it.each`
  width        | height       | outputAttributes
  ${300}       | ${undefined} | ${'width=300'}
  ${undefined} | ${300}       | ${'height=300'}
  ${300}       | ${300}       | ${'width=300 height=300'}
  ${'300%'}    | ${'300px'}   | ${'width="300%" height="300px"'}
`(
  'correctly serializes an image with width and height attributes',
  ({ width, height, outputAttributes }) => {
    const imageAttrs = { src: 'img.jpg', alt: 'foo bar' };

    if (width) imageAttrs.width = width;
    if (height) imageAttrs.height = height;

    expect(serialize(paragraph(image(imageAttrs)))).toBe(
      `![foo bar](img.jpg){${outputAttributes}}`,
    );
  },
);

it('does not serialize an image when src and canonicalSrc are empty', () => {
  expect(serialize(paragraph(image({})))).toBe('');
});

it('correctly serializes an image with a title', () => {
  expect(serialize(paragraph(image({ src: 'img.jpg', title: 'baz', alt: 'foo bar' })))).toBe(
    '![foo bar](img.jpg "baz")',
  );
});

it('correctly serializes an image with a canonicalSrc', () => {
  expect(
    serialize(
      paragraph(
        image({
          src: '/uploads/abcde/file.png',
          alt: 'this is an image',
          canonicalSrc: 'file.png',
          title: 'foo bar baz',
        }),
      ),
    ),
  ).toBe('![this is an image](file.png "foo bar baz")');
});

it('does not use the canonicalSrc if options.useCanonicalSrc=false', () => {
  expect(
    serializeWithOptions(
      { useCanonicalSrc: false },
      paragraph(
        image({
          src: '/uploads/abcde/file.png',
          alt: 'this is an image',
          canonicalSrc: 'file.png',
          title: 'foo bar baz',
        }),
      ),
    ),
  ).toBe('![this is an image](/uploads/abcde/file.png "foo bar baz")');
});

it('correctly serializes image references', () => {
  expect(
    serialize(
      paragraph(
        image({
          canonicalSrc: 'gitlab-url',
          src: 'image.svg',
          alt: 'GitLab',
          isReference: true,
        }),
      ),
    ),
  ).toBe('![GitLab][gitlab-url]');
});

it.each`
  src
  ${'data:image/png;base64,iVBORw0KGgoAAAAN'}
  ${'blob:https://gitlab.com/1234-5678-9012-3456'}
`('omits images with data/blob urls when serializing', ({ src }) => {
  expect(serialize(paragraph(image({ src, alt: 'image' })))).toBe('');
});

it('does not escape url in an image', () => {
  expect(
    serialize(paragraph(image({ src: 'https://example.com/image__1_.png', alt: 'image' }))),
  ).toBe('![image](https://example.com/image__1_.png)');
});

it('serializes image as an HTML tag if sourceTagName is defined', () => {
  const imageAttrs = { src: 'img.jpg', alt: 'image', ...sourceTag('img') };

  expect(serialize(paragraph(image(imageAttrs)))).toBe('<img src="img.jpg" alt="image">');

  expect(serialize(paragraph(image({ ...imageAttrs, width: 300, height: 300 })))).toBe(
    '<img src="img.jpg" alt="image" width="300" height="300">',
  );

  expect(serialize(paragraph(image({ ...imageAttrs, title: 'image title' })))).toBe(
    '<img src="img.jpg" alt="image" title="image title">',
  );
});

it('does not serialize image as HTML if sourceTagName is not img', () => {
  const imageAttrs = { src: 'img.jpg', alt: 'image', ...sourceTag('a') };

  expect(serialize(paragraph(image(imageAttrs)))).toBe('![image](img.jpg)');

  expect(serialize(paragraph(image({ ...imageAttrs, width: 300, height: 300 })))).toBe(
    '![image](img.jpg){width=300 height=300}',
  );

  expect(serialize(paragraph(image({ ...imageAttrs, title: 'image title' })))).toBe(
    '![image](img.jpg "image title")',
  );
});
