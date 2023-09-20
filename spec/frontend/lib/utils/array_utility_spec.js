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

  describe('getDuplicateItemsFromArray', () => {
    it.each`
      array                                  | result
      ${[]}                                  | ${[]}
      ${[1, 2, 2, 3, 3, 4]}                  | ${[2, 3]}
      ${[1, 2, 3, 2, 3, 4]}                  | ${[2, 3]}
      ${['foo', 'bar', 'bar', 'foo', 'baz']} | ${['bar', 'foo']}
      ${['foo', 'foo', 'bar', 'foo', 'bar']} | ${['foo', 'bar']}
    `('given $array will return $result', ({ array, result }) => {
      expect(arrayUtils.getDuplicateItemsFromArray(array)).toEqual(result);
    });
  });

  describe('toggleArrayItem', () => {
    it('adds an item to the array if it does not exist', () => {
      expect(arrayUtils.toggleArrayItem([], 'item')).toStrictEqual(['item']);
    });

    it('removes an item from the array if it already exists', () => {
      expect(arrayUtils.toggleArrayItem(['item'], 'item')).toStrictEqual([]);
    });

    describe('pass by value', () => {
      it('does not toggle the array item when passed a new object', () => {
        expect(arrayUtils.toggleArrayItem([{ a: 1 }], { a: 1 })).toStrictEqual([
          { a: 1 },
          { a: 1 },
        ]);
      });

      it('does not toggle the array item when passed a new array', () => {
        expect(arrayUtils.toggleArrayItem([[1]], [1])).toStrictEqual([[1], [1]]);
      });
    });

    describe('pass by reference', () => {
      const array = [1];
      const object = { a: 1 };

      it('toggles the array item when passed a object reference', () => {
        expect(arrayUtils.toggleArrayItem([object], object)).toStrictEqual([]);
      });

      it('toggles the array item when passed an array reference', () => {
        expect(arrayUtils.toggleArrayItem([array], array)).toStrictEqual([]);
      });
    });
  });
});
