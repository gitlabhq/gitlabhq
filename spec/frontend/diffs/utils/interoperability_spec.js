import {
  getInteropInlineAttributes,
  getInteropNewSideAttributes,
  getInteropOldSideAttributes,
  ATTR_TYPE,
  ATTR_LINE,
  ATTR_NEW_LINE,
  ATTR_OLD_LINE,
} from '~/diffs/utils/interoperability';

describe('~/diffs/utils/interoperability', () => {
  describe('getInteropInlineAttributes', () => {
    it.each([
      ['with null input', { input: null, output: null }],
      [
        'with type=old input',
        {
          input: { type: 'old', old_line: 3, new_line: 5 },
          output: { [ATTR_TYPE]: 'old', [ATTR_LINE]: 3, [ATTR_OLD_LINE]: 3, [ATTR_NEW_LINE]: 5 },
        },
      ],
      [
        'with type=old-nonewline input',
        {
          input: { type: 'old-nonewline', old_line: 3, new_line: 5 },
          output: { [ATTR_TYPE]: 'old', [ATTR_LINE]: 3, [ATTR_OLD_LINE]: 3, [ATTR_NEW_LINE]: 5 },
        },
      ],
      [
        'with type=new input',
        {
          input: { type: 'new', old_line: 3, new_line: 5 },
          output: { [ATTR_TYPE]: 'new', [ATTR_LINE]: 5, [ATTR_OLD_LINE]: 3, [ATTR_NEW_LINE]: 5 },
        },
      ],
      [
        'with type=bogus input',
        {
          input: { type: 'bogus', old_line: 3, new_line: 5 },
          output: { [ATTR_TYPE]: 'new', [ATTR_LINE]: 5, [ATTR_OLD_LINE]: 3, [ATTR_NEW_LINE]: 5 },
        },
      ],
    ])('%s', (desc, { input, output }) => {
      expect(getInteropInlineAttributes(input)).toEqual(output);
    });
  });

  describe('getInteropOldSideAttributes', () => {
    it.each`
      input              | output
      ${null}            | ${null}
      ${{ old_line: 2 }} | ${{ [ATTR_TYPE]: 'old', [ATTR_LINE]: 2, [ATTR_OLD_LINE]: 2 }}
    `('with input=$input', ({ input, output }) => {
      expect(getInteropOldSideAttributes(input)).toEqual(output);
    });
  });

  describe('getInteropNewSideAttributes', () => {
    it.each`
      input              | output
      ${null}            | ${null}
      ${{ new_line: 2 }} | ${{ [ATTR_TYPE]: 'new', [ATTR_LINE]: 2, [ATTR_NEW_LINE]: 2 }}
    `('with input=$input', ({ input, output }) => {
      expect(getInteropNewSideAttributes(input)).toEqual(output);
    });
  });
});
