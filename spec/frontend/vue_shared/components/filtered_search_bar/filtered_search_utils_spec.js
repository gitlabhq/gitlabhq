import * as filteredSearchUtils from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';

describe('Filtered Search Utils', () => {
  describe('stripQuotes', () => {
    it.each`
      inputValue     | outputValue
      ${'"Foo Bar"'} | ${'Foo Bar'}
      ${"'Foo Bar'"} | ${'Foo Bar'}
      ${'FooBar'}    | ${'FooBar'}
      ${"Foo'Bar"}   | ${"Foo'Bar"}
      ${'Foo"Bar'}   | ${'Foo"Bar'}
    `(
      'returns string $outputValue when called with string $inputValue',
      ({ inputValue, outputValue }) => {
        expect(filteredSearchUtils.stripQuotes(inputValue)).toBe(outputValue);
      },
    );
  });
});
