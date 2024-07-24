import { serialize, builders } from '../../serialization_utils';

const { paragraph, audio } = builders;

it('correctly serializes audio', () => {
  expect(serialize(paragraph(audio({ alt: 'audio', canonicalSrc: 'audio.mp3' })))).toBe(
    `![audio](audio.mp3)`,
  );
});
