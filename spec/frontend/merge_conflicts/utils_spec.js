import * as utils from '~/merge_conflicts/utils';
import { conflictsMock } from './mock_data';

describe('merge conflicts utils', () => {
  describe('getFilePath', () => {
    it('returns new path if they are the same', () => {
      expect(utils.getFilePath({ new_path: 'a', old_path: 'a' })).toBe('a');
    });

    it('returns concatenated paths if they are different', () => {
      expect(utils.getFilePath({ new_path: 'b', old_path: 'a' })).toBe('a → b');
    });
  });

  describe('checkLineLengths', () => {
    it('add empty lines to the left when right has more lines', () => {
      const result = utils.checkLineLengths({ left: [1], right: [1, 2] });

      expect(result.left).toHaveLength(result.right.length);
      expect(result.left).toStrictEqual([1, { lineType: 'emptyLine', richText: '' }]);
    });

    it('add empty lines to the right when left has more lines', () => {
      const result = utils.checkLineLengths({ left: [1, 2], right: [1] });

      expect(result.right).toHaveLength(result.left.length);
      expect(result.right).toStrictEqual([1, { lineType: 'emptyLine', richText: '' }]);
    });
  });

  describe('getHeadHeaderLine', () => {
    it('decorates the id', () => {
      expect(utils.getHeadHeaderLine(1, conflictsMock)).toStrictEqual({
        buttonTitle: 'Use ours',
        id: 1,
        isHead: true,
        isHeader: true,
        isSelected: false,
        isUnselected: false,
        richText: '>>>>>>> 4fcf0ele: File added (our changes)',
        section: 'head',
        type: 'new',
      });
    });
  });

  describe('decorateLineForInlineView', () => {
    it.each`
      type       | truthyProp
      ${'new'}   | ${'isHead'}
      ${'old'}   | ${'isOrigin'}
      ${'match'} | ${'hasMatch'}
    `(
      'when the type is $type decorates the line with $truthyProp set as true',
      ({ type, truthyProp }) => {
        expect(utils.decorateLineForInlineView({ type, rich_text: 'rich' }, 1, true)).toStrictEqual(
          {
            id: 1,
            hasConflict: true,
            isHead: false,
            isOrigin: false,
            hasMatch: false,
            richText: 'rich',
            isSelected: false,
            isUnselected: false,
            [truthyProp]: true,
          },
        );
      },
    );
  });

  describe('getLineForParallelView', () => {
    it.todo('should return a proper value');
  });

  describe('getOriginHeaderLine', () => {
    it('decorates the id', () => {
      expect(utils.getOriginHeaderLine(1, conflictsMock)).toStrictEqual({
        buttonTitle: 'Use theirs',
        id: 1,
        isHeader: true,
        isOrigin: true,
        isSelected: false,
        isUnselected: false,
        richText: '<<<<<<< HEAD: main (their changes)',
        section: 'origin',
        type: 'old',
      });
    });
  });
  describe('setInlineLine', () => {
    it.todo('should return a proper value');
  });
  describe('setParallelLine', () => {
    it.todo('should return a proper value');
  });
  describe('decorateFiles', () => {
    it.todo('should return a proper value');
  });
  describe('restoreFileLinesState', () => {
    it.todo('should return a proper value');
  });
  describe('markLine', () => {
    it.todo('should return a proper value');
  });
});
