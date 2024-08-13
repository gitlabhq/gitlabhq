import { serialize, serializeWithOptions, builders, source } from '../../serialization_utils';

const { paragraph, inlineDiff } = builders;

it('correctly serializes inline diff', () => {
  expect(
    serialize(
      paragraph(
        inlineDiff({ type: 'addition' }, '+30 lines'),
        inlineDiff({ type: 'deletion' }, '-10 lines'),
      ),
    ),
  ).toBe('{++30 lines+}{--10 lines-}');
});

it.each`
  type          | start   | end
  ${'addition'} | ${'{+'} | ${'+}'}
  ${'deletion'} | ${'{-'} | ${'-}'}
`('correctly serializes inline diff with sourcemap', ({ type, start, end }) => {
  const sourceMarkdown = source(`${start}+30  lines${end}`);
  const diffAttrs = { ...sourceMarkdown, type };

  expect(serialize(paragraph(inlineDiff(diffAttrs, '+30 lines')))).toBe(`${start}+30  lines${end}`);

  expect(
    serializeWithOptions(
      { pristineDoc: paragraph(inlineDiff(diffAttrs, '+30 lines')) },
      paragraph(inlineDiff(diffAttrs, '+40 lines')),
    ),
  ).toBe(`${start}+40 lines${end}`);
});
