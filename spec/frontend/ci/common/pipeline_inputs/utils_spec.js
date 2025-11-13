import {
  getSkeletonRectProps,
  formatValue,
  hasValueChanged,
  formatValueLines,
  formatMetadataLines,
  formatInputLines,
  formatInputsForDisplay,
  findMatchingRule,
  processQueryInputs,
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

describe('Pipeline Inputs Rule Evaluator', () => {
  const mockInputs = [
    { name: 'cloud_provider', value: 'aws', isSelected: true },
    { name: 'environment', value: 'dev', isSelected: true },
    { name: 'region', value: 'us-east-1', isSelected: true },
    { name: 'instance_count', value: '5', isSelected: true },
  ];

  describe('findMatchingRule', () => {
    const rules = [
      {
        conditionTree: {
          operator: 'AND',
          field: null,
          value: null,
          children: [
            { field: 'cloud_provider', operator: 'equals', value: 'aws' },
            { field: 'environment', operator: 'equals', value: 'dev' },
          ],
        },
        options: ['t3.micro', 't3.small'],
        default: 't3.micro',
      },
      {
        conditionTree: {
          operator: 'AND',
          field: null,
          value: null,
          children: [
            { field: 'cloud_provider', operator: 'equals', value: 'aws' },
            { field: 'environment', operator: 'equals', value: 'prod' },
          ],
        },
        options: ['m5.large', 'm5.xlarge'],
        default: 'm5.large',
      },
      {
        conditionTree: {
          field: 'cloud_provider',
          operator: 'equals',
          value: 'gcp',
        },
        options: ['e2-small', 'e2-medium'],
        default: 'e2-small',
      },
      {
        conditionTree: {},
        options: ['standard'],
        default: 'standard',
      },
    ];

    it('returns the first matching rule when conditions are met', () => {
      const result = findMatchingRule(rules, mockInputs);

      expect(result).toEqual({
        conditionTree: {
          operator: 'AND',
          field: null,
          value: null,
          children: [
            { field: 'cloud_provider', operator: 'equals', value: 'aws' },
            { field: 'environment', operator: 'equals', value: 'dev' },
          ],
        },
        options: ['t3.micro', 't3.small'],
        default: 't3.micro',
      });
    });

    it('returns the second rule when first does not match', () => {
      const prodInputs = [
        { name: 'cloud_provider', value: 'aws', isSelected: true },
        { name: 'environment', value: 'prod', isSelected: true },
      ];

      const result = findMatchingRule(rules, prodInputs);

      expect(result).toEqual({
        conditionTree: {
          operator: 'AND',
          field: null,
          value: null,
          children: [
            { field: 'cloud_provider', operator: 'equals', value: 'aws' },
            { field: 'environment', operator: 'equals', value: 'prod' },
          ],
        },
        options: ['m5.large', 'm5.xlarge'],
        default: 'm5.large',
      });
    });

    it('returns fallback rule with empty conditionTree when no specific rules match', () => {
      const azureInputs = [
        { name: 'cloud_provider', value: 'azure', isSelected: true },
        { name: 'environment', value: 'dev', isSelected: true },
      ];

      const result = findMatchingRule(rules, azureInputs);

      expect(result).toEqual({
        conditionTree: {},
        options: ['standard'],
        default: 'standard',
      });
    });

    it('returns undefined when rules is not an array', () => {
      expect(findMatchingRule(null, mockInputs)).toBeUndefined();
      expect(findMatchingRule(undefined, mockInputs)).toBeUndefined();
      expect(findMatchingRule('not-an-array', mockInputs)).toBeUndefined();
      expect(findMatchingRule({}, mockInputs)).toBeUndefined();
    });

    it('returns undefined when rules array is empty', () => {
      const result = findMatchingRule([], mockInputs);

      expect(result).toBeUndefined();
    });

    it('returns undefined when no rules match and no fallback exists', () => {
      const rulesWithoutFallback = [
        {
          conditionTree: {
            field: 'cloud_provider',
            operator: 'equals',
            value: 'gcp',
          },
          options: ['e2-small'],
          default: 'e2-small',
        },
      ];

      const result = findMatchingRule(rulesWithoutFallback, mockInputs);

      expect(result).toBeUndefined();
    });

    it('handles rules with null conditionTree as fallback', () => {
      const rulesWithNullCondition = [
        {
          conditionTree: {
            field: 'cloud_provider',
            operator: 'equals',
            value: 'gcp',
          },
          options: ['e2-small'],
          default: 'e2-small',
        },
        {
          conditionTree: null,
          options: ['fallback'],
          default: 'fallback',
        },
      ];

      const result = findMatchingRule(rulesWithNullCondition, mockInputs);

      expect(result).toEqual({
        conditionTree: null,
        options: ['fallback'],
        default: 'fallback',
      });
    });

    it('returns first matching rule in order when multiple rules match', () => {
      const multiMatchRules = [
        {
          conditionTree: {
            field: 'cloud_provider',
            operator: 'equals',
            value: 'aws',
          },
          options: ['first-match'],
          default: 'first',
        },
        {
          conditionTree: {
            field: 'environment',
            operator: 'equals',
            value: 'dev',
          },
          options: ['second-match'],
          default: 'second',
        },
      ];

      const result = findMatchingRule(multiMatchRules, mockInputs);

      expect(result).toEqual({
        conditionTree: {
          field: 'cloud_provider',
          operator: 'equals',
          value: 'aws',
        },
        options: ['first-match'],
        default: 'first',
      });
    });

    it('evaluates simple equality condition in rule', () => {
      const testRules = [
        {
          conditionTree: { field: 'cloud_provider', operator: 'equals', value: 'aws' },
          options: ['match'],
          default: 'match',
        },
      ];

      const result = findMatchingRule(testRules, mockInputs);

      expect(result).toBeDefined();
      expect(result.options).toEqual(['match']);
    });

    it('evaluates NOT condition in rule', () => {
      const testRules = [
        {
          conditionTree: {
            operator: 'NOT',
            field: null,
            value: null,
            children: [{ field: 'cloud_provider', operator: 'equals', value: 'gcp' }],
          },
          options: ['not-gcp'],
          default: 'not-gcp',
        },
      ];

      const result = findMatchingRule(testRules, mockInputs);

      expect(result).toBeDefined();
      expect(result.options).toEqual(['not-gcp']);
    });

    it('evaluates AND conditions in rule', () => {
      const testRules = [
        {
          conditionTree: {
            operator: 'AND',
            field: null,
            value: null,
            children: [
              { field: 'cloud_provider', operator: 'equals', value: 'aws' },
              { field: 'environment', operator: 'equals', value: 'dev' },
            ],
          },
          options: ['aws-dev'],
          default: 'aws-dev',
        },
      ];

      const result = findMatchingRule(testRules, mockInputs);

      expect(result).toBeDefined();
      expect(result.options).toEqual(['aws-dev']);
    });

    it('evaluates OR conditions in rule', () => {
      const testRules = [
        {
          conditionTree: {
            operator: 'OR',
            field: null,
            value: null,
            children: [
              { field: 'cloud_provider', operator: 'equals', value: 'gcp' },
              { field: 'environment', operator: 'equals', value: 'dev' },
            ],
          },
          options: ['gcp-or-dev'],
          default: 'gcp-or-dev',
        },
      ];

      const result = findMatchingRule(testRules, mockInputs);

      expect(result).toBeDefined();
      expect(result.options).toEqual(['gcp-or-dev']);
    });

    it('evaluates nested conditions in rule', () => {
      const testRules = [
        {
          conditionTree: {
            operator: 'OR',
            field: null,
            value: null,
            children: [
              {
                operator: 'AND',
                field: null,
                value: null,
                children: [
                  { field: 'cloud_provider', operator: 'equals', value: 'aws' },
                  { field: 'environment', operator: 'equals', value: 'dev' },
                ],
              },
              { field: 'cloud_provider', operator: 'equals', value: 'gcp' },
            ],
          },
          options: ['complex-match'],
          default: 'complex-match',
        },
      ];

      const result = findMatchingRule(testRules, mockInputs);

      expect(result).toBeDefined();
      expect(result.options).toEqual(['complex-match']);
    });
  });

  describe('processQueryInputs', () => {
    const queryInputs = [
      {
        name: 'input1',
        default: 'default1',
        type: 'STRING',
        rules: null,
      },
      {
        name: 'input2',
        default: 'default2',
        type: 'STRING',
        rules: null,
      },
      {
        name: 'dynamic_input',
        default: '',
        type: 'STRING',
        rules: [{ conditionTree: {}, options: ['a'], default: 'a' }],
      },
    ];

    it('processes all inputs and detects dynamic rules', () => {
      const savedInputs = [{ name: 'input1', value: 'saved1' }];

      const result = processQueryInputs(queryInputs, savedInputs, false);

      expect(result.hasDynamicRules).toBe(true);
      expect(result.processedInputs).toHaveLength(3);
      expect(result.processedInputs[0]).toMatchObject({
        name: 'input1',
        value: 'saved1',
        isSelected: true,
        hasRules: false,
      });
      expect(result.processedInputs[1]).toMatchObject({
        name: 'input2',
        value: 'default2',
        isSelected: false,
        hasRules: false,
      });
      expect(result.processedInputs[2]).toMatchObject({
        name: 'dynamic_input',
        hasRules: true,
      });
    });

    it('returns hasDynamicRules as false when no inputs have rules', () => {
      const staticInputs = [
        { name: 'input1', default: 'default1', type: 'STRING', rules: null },
        { name: 'input2', default: 'default2', type: 'STRING', rules: null },
      ];

      const result = processQueryInputs(staticInputs, [], false);

      expect(result.hasDynamicRules).toBe(false);
      expect(result.processedInputs).toHaveLength(2);
    });

    it('preselects all inputs when preselectAllInputs is true', () => {
      const result = processQueryInputs(queryInputs, [], true);

      expect(result.processedInputs.every((input) => input.isSelected)).toBe(true);
    });

    it('handles empty query inputs', () => {
      const result = processQueryInputs([], [], false);

      expect(result.hasDynamicRules).toBe(false);
      expect(result.processedInputs).toEqual([]);
    });

    it('handles empty saved inputs', () => {
      const result = processQueryInputs(queryInputs, [], false);

      expect(result.processedInputs).toHaveLength(3);
      expect(result.processedInputs.every((input) => input.savedValue === undefined)).toBe(true);
    });

    it('processes input with saved value correctly', () => {
      const testQueryInputs = [
        { name: 'saved_input', default: 'default_value', type: 'STRING', rules: null },
      ];
      const savedInputs = [{ name: 'saved_input', value: 'saved_value' }];

      const result = processQueryInputs(testQueryInputs, savedInputs, false);

      expect(result.processedInputs[0]).toMatchObject({
        name: 'saved_input',
        savedValue: 'saved_value',
        value: 'saved_value',
        isSelected: true,
        hasRules: false,
      });
    });

    it('processes input without saved value using default', () => {
      const testQueryInputs = [
        { name: 'new_input', default: 'default_value', type: 'STRING', rules: null },
      ];

      const result = processQueryInputs(testQueryInputs, [], false);

      expect(result.processedInputs[0]).toMatchObject({
        name: 'new_input',
        savedValue: undefined,
        value: 'default_value',
        isSelected: false,
        hasRules: false,
      });
    });

    it('sets hasRules correctly for inputs with rules', () => {
      const testQueryInputs = [
        {
          name: 'dynamic_input',
          default: '',
          type: 'STRING',
          rules: [{ conditionTree: {}, options: ['a'], default: 'a' }],
        },
      ];

      const result = processQueryInputs(testQueryInputs, [], false);

      expect(result.processedInputs[0].hasRules).toBe(true);
    });

    it('handles inputs with various value types in saved inputs', () => {
      const testQueryInputs = [
        { name: 'string_input', default: '', type: 'STRING', rules: null },
        { name: 'number_input', default: 0, type: 'NUMBER', rules: null },
        { name: 'boolean_input', default: false, type: 'BOOLEAN', rules: null },
      ];
      const savedInputs = [
        { name: 'string_input', value: 'text' },
        { name: 'number_input', value: 42 },
        { name: 'boolean_input', value: true },
      ];

      const result = processQueryInputs(testQueryInputs, savedInputs, false);

      expect(result.processedInputs[0].value).toBe('text');
      expect(result.processedInputs[1].value).toBe(42);
      expect(result.processedInputs[2].value).toBe(true);
    });
  });
});
