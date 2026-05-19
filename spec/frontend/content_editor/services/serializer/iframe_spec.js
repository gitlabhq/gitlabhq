import { serialize, builders } from '../../serialization_utils';

const { paragraph, iframe } = builders;

it('correctly serializes iframe as image markdown', () => {
  expect(
    serialize(
      paragraph(
        iframe({
          alt: 'YouTube video',
          canonicalSrc: 'https://www.youtube.com/watch?v=abc123',
        }),
      ),
    ),
  ).toBe('![YouTube video](https://www.youtube.com/watch?v=abc123)');
});

it('serializes iframe with width and height', () => {
  expect(
    serialize(
      paragraph(
        iframe({
          alt: 'Figma design',
          canonicalSrc: 'https://www.figma.com/design/abc',
          width: 800,
          height: 450,
        }),
      ),
    ),
  ).toBe('![Figma design](https://www.figma.com/design/abc){width=800 height=450}');
});

it('serializes iframe without alt text', () => {
  expect(
    serialize(
      paragraph(
        iframe({
          canonicalSrc: 'https://www.youtube.com/watch?v=abc123',
        }),
      ),
    ),
  ).toBe('![](https://www.youtube.com/watch?v=abc123)');
});
