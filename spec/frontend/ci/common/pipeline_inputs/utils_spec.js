import {
  getSkeletonRectProps,
  formatValue,
  hasValueChanged,
  formatValueLines,
  formatMetadataLines,
  formatInputLines,
  formatInputsForDisplay,
} from '~/ci/common/pipeline_inputs/utils';

describe('Skeleton utils', () => {
  describe('getSkeletonRectProps', () => {
    it.each`
      columnIndex | rowIndex | expectedX  | expectedY
      ${0}        | ${0}     | ${'0%'}    | ${0}
      ${1}        | ${0}     | ${'25.5%'} | ${0}
      ${2}        | ${0}     | ${'51%'}   | ${0}
      ${3}        | ${0}     | ${'76.5%'} | ${0}
      ${0}        | ${1}     | ${'0%'}    | ${10}
      ${2}        | ${3}     | ${'51%'}   | ${30}
    `(
      'calculates correct position for col $columnIndex, row $rowIndex',
      ({ columnIndex, rowIndex, expectedX, expectedY }) => {
        const result = getSkeletonRectProps(columnIndex, rowIndex);

        expect(result.x).toBe(expectedX);
        expect(result.y).toBe(expectedY);
        expect(result.width).toBe('23%');
        expect(result.height).toBe(6);
        expect(result.rx).toBe(2);
        expect(result.ry).toBe(2);
      },
    );
  });
});

describe('Input Formatter Utils', () => {
  describe('formatValue', () => {
    it.each([
      { input: 'hello world', expected: '"hello world"', description: 'regular string' },
      { input: '', expected: '""', description: 'empty string' },
      { input: 42, expected: '42', description: 'positive integer' },
      { input: 0, expected: '0', description: 'zero' },
      { input: -1, expected: '-1', description: 'negative integer' },
      { input: 3.14, expected: '3.14', description: 'decimal number' },
      { input: true, expected: 'true', description: 'boolean true' },
      { input: false, expected: 'false', description: 'boolean false' },
      { input: null, expected: 'null', description: 'null value' },
      { input: undefined, expected: 'undefined', description: 'undefined value' },
      { input: { key: 'value' }, expected: '{"key":"value"}', description: 'simple object' },
      { input: {}, expected: '{}', description: 'empty object' },
      {
        input: { nested: { count: 42 } },
        expected: '{"nested":{"count":42}}',
        description: 'nested object',
      },
      { input: [1, 2, 3], expected: '[1,2,3]', description: 'number array' },
      { input: [], expected: '[]', description: 'empty array' },
      { input: ['a', 'b'], expected: '["a","b"]', description: 'string array' },
      {
        input: [{ id: 1 }, { id: 2 }],
        expected: '[{"id":1},{"id":2}]',
        description: 'object array',
      },
    ])('formats $description correctly', ({ input, expected }) => {
      expect(formatValue(input)).toBe(expected);
    });
  });

  describe('hasValueChanged', () => {
    describe('primitive values', () => {
      it.each([
        {
          value: 'new-value',
          defaultValue: 'default-value',
          expected: true,
          description: 'different values',
        },
        {
          value: 'saved-value',
          defaultValue: 'saved-value',
          expected: false,
          description: 'unchanged values',
        },
      ])('returns $expected for $description', ({ value, defaultValue, expected }) => {
        expect(hasValueChanged(value, defaultValue)).toBe(expected);
      });
    });

    describe('object values', () => {
      it.each([
        {
          value: { key: 'value' },
          defaultValue: { key: 'different' },
          expected: true,
          description: 'different object values',
        },
        {
          value: [1, 2, 3],
          defaultValue: [1, 2, 4],
          expected: true,
          description: 'different arrays',
        },
        {
          value: { key: 'value' },
          defaultValue: { key: 'value' },
          expected: false,
          description: 'same object values',
        },
        {
          value: [1, 2, 3],
          defaultValue: [1, 2, 3],
          expected: false,
          description: 'same arrays',
        },
        {
          value: { nested: { count: 42 } },
          defaultValue: { nested: { count: 42 } },
          expected: false,
          description: 'same nested objects',
        },
      ])('returns $expected for $description', ({ value, defaultValue, expected }) => {
        expect(hasValueChanged(value, defaultValue)).toBe(expected);
      });
    });
  });

  describe('formatValueLines', () => {
    it('returns diff lines for changed values', () => {
      const input = {
        value: 'new_value',
        default: 'old_value',
      };

      const result = formatValueLines(input, true);

      expect(result).toEqual([
        { content: '-   value: "old_value"', type: 'old' },
        { content: '+   value: "new_value"', type: 'new' },
      ]);
    });

    it('returns single value line for unchanged values', () => {
      const input = {
        value: 'same_value',
        default: 'same_value',
      };

      const result = formatValueLines(input, false);

      expect(result).toEqual([{ content: '    value: "same_value"', type: '' }]);
    });
  });

  describe('formatMetadataLines', () => {
    it.each([
      {
        description: 'both type and description when present',
        input: {
          type: 'STRING',
          description: 'A test input',
        },
        expected: [
          { content: '    type: "STRING"', type: '' },
          { content: '    description: "A test input"', type: '' },
        ],
      },
      {
        description: 'only type when description is missing',
        input: {
          type: 'NUMBER',
        },
        expected: [{ content: '    type: "NUMBER"', type: '' }],
      },
      {
        description: 'only description when type is missing',
        input: {
          description: 'No type specified',
        },
        expected: [{ content: '    description: "No type specified"', type: '' }],
      },
      {
        description: 'empty array when both are missing',
        input: {},
        expected: [],
      },
    ])('returns $description', ({ input, expected }) => {
      const result = formatMetadataLines(input);
      expect(result).toEqual(expected);
    });
  });

  describe('formatInputLines', () => {
    it('formats complete input with all fields', () => {
      const input = {
        name: 'test_input',
        value: 'new_value',
        default: 'old_value',
        type: 'STRING',
        description: 'Test description',
      };

      const result = formatInputLines(input);

      expect(result).toEqual([
        { content: 'test_input:', type: '' },
        { content: '-   value: "old_value"', type: 'old' },
        { content: '+   value: "new_value"', type: 'new' },
        { content: '    type: "STRING"', type: '' },
        { content: '    description: "Test description"', type: '' },
        { content: '', type: '' },
      ]);
    });

    it('formats input with minimal fields', () => {
      const input = {
        name: 'simple_input',
        value: 'value',
        default: 'value',
      };

      const result = formatInputLines(input);

      expect(result).toEqual([
        { content: 'simple_input:', type: '' },
        { content: '    value: "value"', type: '' },
        { content: '', type: '' },
      ]);
    });
  });

  describe('formatInputsForDisplay', () => {
    it('formats multiple inputs correctly', () => {
      const inputs = [
        {
          name: 'first_input',
          value: 'new',
          default: 'old',
          type: 'STRING',
        },
        {
          name: 'second_input',
          value: 42,
          default: 42,
          type: 'NUMBER',
          description: 'A number input',
        },
      ];

      const result = formatInputsForDisplay(inputs);

      expect(result).toEqual([
        { content: 'first_input:', type: '' },
        { content: '-   value: "old"', type: 'old' },
        { content: '+   value: "new"', type: 'new' },
        { content: '    type: "STRING"', type: '' },
        { content: '', type: '' },
        { content: 'second_input:', type: '' },
        { content: '    value: 42', type: '' },
        { content: '    type: "NUMBER"', type: '' },
        { content: '    description: "A number input"', type: '' },
        { content: '', type: '' },
      ]);
    });

    it('handles empty inputs array', () => {
      const result = formatInputsForDisplay([]);
      expect(result).toEqual([]);
    });
  });

  describe('edge cases', () => {
    it('handles inputs with null/undefined values', () => {
      const input = {
        name: 'null_input',
        value: null,
        default: undefined,
      };

      const result = formatInputLines(input);

      expect(result).toEqual([
        { content: 'null_input:', type: '' },
        { content: '-   value: undefined', type: 'old' },
        { content: '+   value: null', type: 'new' },
        { content: '', type: '' },
      ]);
    });

    it('handles inputs with empty strings vs null', () => {
      const input = {
        name: 'empty_vs_null',
        value: '',
        default: null,
      };

      const result = formatInputLines(input);

      expect(result).toEqual([
        { content: 'empty_vs_null:', type: '' },
        { content: '-   value: null', type: 'old' },
        { content: '+   value: ""', type: 'new' },
        { content: '', type: '' },
      ]);
    });
  });
});
