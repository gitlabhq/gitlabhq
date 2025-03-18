import { serialize, builders } from '../../serialization_utils';

const { paragraph, time } = builders;

it('correctly serializes a time tag', () => {
  expect(
    serialize(
      paragraph(
        time(
          { title: '24 September 2024 at 04:33:04 pm CEST', datetime: '2024-09-24T16:33:04+02:00' },
          '24 September 2024 at 04:33:04 pm CEST',
        ),
      ),
    ),
  ).toBe(
    '<time title="24 September 2024 at 04:33:04 pm CEST" datetime="2024-09-24T16:33:04+02:00">24 September 2024 at 04:33:04 pm CEST</time>',
  );
});
