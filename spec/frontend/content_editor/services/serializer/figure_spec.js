import { serialize, builders } from '../../serialization_utils';

const { paragraph, figure, figureCaption, image, italic } = builders;

it('correctly renders figure', () => {
  expect(
    serialize(
      figure(
        paragraph(image({ src: 'elephant.jpg', alt: 'An elephant at sunset' })),
        figureCaption('An elephant at sunset'),
      ),
    ),
  ).toBe(
    `
<figure>

![An elephant at sunset](elephant.jpg)

<figcaption>An elephant at sunset</figcaption>
</figure>
      `.trim(),
  );
});

it('correctly renders figure with styled caption', () => {
  expect(
    serialize(
      figure(
        paragraph(image({ src: 'elephant.jpg', alt: 'An elephant at sunset' })),
        figureCaption(italic('An elephant at sunset')),
      ),
    ),
  ).toBe(
    `
<figure>

![An elephant at sunset](elephant.jpg)

<figcaption>

_An elephant at sunset_

</figcaption>
</figure>
      `.trim(),
  );
});
