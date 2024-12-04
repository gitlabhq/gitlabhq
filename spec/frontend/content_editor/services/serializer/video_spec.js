import { serialize, builders } from '../../serialization_utils';

const { paragraph, video } = builders;

it('correctly serializes video', () => {
  expect(serialize(paragraph(video({ alt: 'video', canonicalSrc: 'video.mov' })))).toBe(
    `![video](video.mov)`,
  );
});

it('serializes video with width and height', () => {
  expect(
    serialize(
      paragraph(video({ alt: 'video', canonicalSrc: 'video.mov', width: 400, height: 300 })),
    ),
  ).toBe(`![video](video.mov){width=400 height=300}`);
});
