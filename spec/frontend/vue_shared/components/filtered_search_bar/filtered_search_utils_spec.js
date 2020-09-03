import * as filteredSearchUtils from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';

import {
  tokenValueAuthor,
  tokenValueLabel,
  tokenValueMilestone,
  tokenValuePlain,
} from './mock_data';

describe('Filtered Search Utils', () => {
  describe('stripQuotes', () => {
    it.each`
      inputValue     | outputValue
      ${'"Foo Bar"'} | ${'Foo Bar'}
      ${"'Foo Bar'"} | ${'Foo Bar'}
      ${'FooBar'}    | ${'FooBar'}
      ${"Foo'Bar"}   | ${"Foo'Bar"}
      ${'Foo"Bar'}   | ${'Foo"Bar'}
      ${'Foo Bar'}   | ${'Foo Bar'}
    `(
      'returns string $outputValue when called with string $inputValue',
      ({ inputValue, outputValue }) => {
        expect(filteredSearchUtils.stripQuotes(inputValue)).toBe(outputValue);
      },
    );
  });

  describe('uniqueTokens', () => {
    it('returns tokens array with duplicates removed', () => {
      expect(
        filteredSearchUtils.uniqueTokens([
          tokenValueAuthor,
          tokenValueLabel,
          tokenValueMilestone,
          tokenValueLabel,
          tokenValuePlain,
        ]),
      ).toHaveLength(4); // Removes 2nd instance of tokenValueLabel
    });

    it('returns tokens array as it is if it does not have duplicates', () => {
      expect(
        filteredSearchUtils.uniqueTokens([
          tokenValueAuthor,
          tokenValueLabel,
          tokenValueMilestone,
          tokenValuePlain,
        ]),
      ).toHaveLength(4);
    });
  });
});
