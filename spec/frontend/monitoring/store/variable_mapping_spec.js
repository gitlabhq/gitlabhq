import { parseTemplatingVariables } from '~/monitoring/stores/variable_mapping';

describe('parseTemplatingVariables', () => {
  const generateMockTemplatingData = data => {
    const vars = data
      ? {
          variables: {
            ...data,
          },
        }
      : {};
    return {
      dashboard: {
        templating: vars,
      },
    };
  };

  const simpleVar = ['value1', 'value2', 'value3'];
  const advVar = {
    label: 'Advanced Var',
    type: 'custom',
    options: {
      values: [
        { value: 'value1', text: 'Var 1 Option 1' },
        {
          value: 'value2',
          text: 'Var 1 Option 2',
          default: true,
        },
      ],
    },
  };
  const advVarWithoutOptions = {
    type: 'custom',
    options: {},
  };
  const advVarWithoutLabel = {
    type: 'custom',
    options: {
      values: [
        { value: 'value1', text: 'Var 1 Option 1' },
        {
          value: 'value2',
          text: 'Var 1 Option 2',
          default: true,
        },
      ],
    },
  };
  const advVarWithoutType = {
    label: 'Variable 2',
    options: {
      values: [
        { value: 'value1', text: 'Var 1 Option 1' },
        {
          value: 'value2',
          text: 'Var 1 Option 2',
          default: true,
        },
      ],
    },
  };

  const responseForSimpleCustomVariable = {
    simpleVar: {
      label: 'simpleVar',
      options: [
        {
          default: false,
          text: 'value1',
          value: 'value1',
        },
        {
          default: false,
          text: 'value2',
          value: 'value2',
        },
        {
          default: false,
          text: 'value3',
          value: 'value3',
        },
      ],
      type: 'custom',
    },
  };

  const responseForAdvancedCustomVariableWithoutOptions = {
    advVarWithoutOptions: {
      label: 'advVarWithoutOptions',
      options: [],
      type: 'custom',
    },
  };

  const responseForAdvancedCustomVariableWithoutLabel = {
    advVarWithoutLabel: {
      label: 'advVarWithoutLabel',
      options: [
        {
          default: false,
          text: 'Var 1 Option 1',
          value: 'value1',
        },
        {
          default: true,
          text: 'Var 1 Option 2',
          value: 'value2',
        },
      ],
      type: 'custom',
    },
  };

  const responseForAdvancedCustomVariable = {
    ...responseForSimpleCustomVariable,
    advVar: {
      label: 'Advanced Var',
      options: [
        {
          default: false,
          text: 'Var 1 Option 1',
          value: 'value1',
        },
        {
          default: true,
          text: 'Var 1 Option 2',
          value: 'value2',
        },
      ],
      type: 'custom',
    },
  };

  it.each`
    case                                                             | input                                                   | expected
    ${'Returns empty object for no dashboard input'}                 | ${{}}                                                   | ${{}}
    ${'Returns empty object for empty dashboard input'}              | ${{ dashboard: {} }}                                    | ${{}}
    ${'Returns empty object for empty templating prop'}              | ${generateMockTemplatingData()}                         | ${{}}
    ${'Returns empty object for empty variables prop'}               | ${generateMockTemplatingData({})}                       | ${{}}
    ${'Returns parsed object for simple variable'}                   | ${generateMockTemplatingData({ simpleVar })}            | ${responseForSimpleCustomVariable}
    ${'Returns parsed object for advanced variable without options'} | ${generateMockTemplatingData({ advVarWithoutOptions })} | ${responseForAdvancedCustomVariableWithoutOptions}
    ${'Returns parsed object for advanced variable without type'}    | ${generateMockTemplatingData({ advVarWithoutType })}    | ${{}}
    ${'Returns parsed object for advanced variable without label'}   | ${generateMockTemplatingData({ advVarWithoutLabel })}   | ${responseForAdvancedCustomVariableWithoutLabel}
    ${'Returns parsed object for simple and advanced variables'}     | ${generateMockTemplatingData({ simpleVar, advVar })}    | ${responseForAdvancedCustomVariable}
  `('$case', ({ input, expected }) => {
    expect(parseTemplatingVariables(input?.dashboard?.templating)).toEqual(expected);
  });
});
