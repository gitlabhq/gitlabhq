import { serialize, builders } from '../../serialization_utils';

const { paragraph, video } = builders;

it('correctly serializes video', () => {
  expect(serialize(paragraph(video({ alt: 'video', canonicalSrc: 'video.mov' })))).toBe(
    `![video](video.mov)`,
  );
});
