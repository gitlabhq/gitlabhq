import * as arrayUtils from '~/lib/utils/array_utility';

describe('array_utility', () => {
  describe('swapArrayItems', () => {
    it.each`
      array              | leftIndex | rightIndex | result
      ${[]}              | ${0}      | ${0}       | ${[]}
      ${[1]}             | ${0}      | ${1}       | ${[1]}
      ${[1, 2]}          | ${0}      | ${0}       | ${[1, 2]}
      ${[1, 2]}          | ${0}      | ${1}       | ${[2, 1]}
      ${[1, 2]}          | ${1}      | ${2}       | ${[1, 2]}
      ${[1, 2]}          | ${2}      | ${1}       | ${[1, 2]}
      ${[1, 2]}          | ${1}      | ${10}      | ${[1, 2]}
      ${[1, 2]}          | ${10}     | ${1}       | ${[1, 2]}
      ${[1, 2]}          | ${1}      | ${-1}      | ${[1, 2]}
      ${[1, 2]}          | ${-1}     | ${1}       | ${[1, 2]}
      ${[1, 2, 3]}       | ${1}      | ${1}       | ${[1, 2, 3]}
      ${[1, 2, 3]}       | ${0}      | ${2}       | ${[3, 2, 1]}
      ${[1, 2, 3, 4]}    | ${0}      | ${2}       | ${[3, 2, 1, 4]}
      ${[1, 2, 3, 4, 5]} | ${0}      | ${4}       | ${[5, 2, 3, 4, 1]}
      ${[1, 2, 3, 4, 5]} | ${1}      | ${2}       | ${[1, 3, 2, 4, 5]}
      ${[1, 2, 3, 4, 5]} | ${2}      | ${1}       | ${[1, 3, 2, 4, 5]}
    `(
      'given $array with index $leftIndex and $rightIndex will return $result',
      ({ array, leftIndex, rightIndex, result }) => {
        const actual = arrayUtils.swapArrayItems(array, leftIndex, rightIndex);
        expect(actual).toEqual(result);
        expect(actual).not.toBe(array);
      },
    );
  });
});
