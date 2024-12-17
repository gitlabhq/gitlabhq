import { serialize, builders, source, sourceTag } from '../../serialization_utils';

const { paragraph, hardBreak } = builders;

it('correctly serializes a line break', () => {
  expect(serialize(paragraph('hello', hardBreak(), 'world'))).toBe('hello\\\nworld');
});

it('correctly serializes a line break with a sourcemap', () => {
  expect(serialize(paragraph('hello', hardBreak(source('\\')), 'world'))).toBe('hello\\\nworld');
  expect(serialize(paragraph('hello', hardBreak(source('')), 'world'))).toBe('hello  \nworld');
});

it('correctly serializes a line break with a source tag', () => {
  expect(serialize(paragraph('hello', hardBreak(sourceTag('br')), 'world'))).toBe('hello<br>world');
});
