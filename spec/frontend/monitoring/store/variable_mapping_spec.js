import { parseTemplatingVariables } from '~/monitoring/stores/variable_mapping';
import { mockTemplatingData, mockTemplatingDataResponses } from '../mock_data';

describe('parseTemplatingVariables', () => {
  it.each`
    case                                                                            | input                                         | expected
    ${'Returns empty object for no dashboard input'}                                | ${{}}                                         | ${{}}
    ${'Returns empty object for empty dashboard input'}                             | ${{ dashboard: {} }}                          | ${{}}
    ${'Returns empty object for empty templating prop'}                             | ${mockTemplatingData.emptyTemplatingProp}     | ${{}}
    ${'Returns empty object for empty variables prop'}                              | ${mockTemplatingData.emptyVariablesProp}      | ${{}}
    ${'Returns parsed object for simple text variable'}                             | ${mockTemplatingData.simpleText}              | ${mockTemplatingDataResponses.simpleText}
    ${'Returns parsed object for advanced text variable'}                           | ${mockTemplatingData.advText}                 | ${mockTemplatingDataResponses.advText}
    ${'Returns parsed object for simple custom variable'}                           | ${mockTemplatingData.simpleCustom}            | ${mockTemplatingDataResponses.simpleCustom}
    ${'Returns parsed object for advanced custom variable without options'}         | ${mockTemplatingData.advCustomWithoutOpts}    | ${mockTemplatingDataResponses.advCustomWithoutOpts}
    ${'Returns parsed object for advanced custom variable for option without text'} | ${mockTemplatingData.advCustomWithoutOptText} | ${mockTemplatingDataResponses.advCustomWithoutOptText}
    ${'Returns parsed object for advanced custom variable without type'}            | ${mockTemplatingData.advCustomWithoutType}    | ${{}}
    ${'Returns parsed object for advanced custom variable without label'}           | ${mockTemplatingData.advCustomWithoutLabel}   | ${mockTemplatingDataResponses.advCustomWithoutLabel}
    ${'Returns parsed object for simple and advanced custom variables'}             | ${mockTemplatingData.simpleAndAdv}            | ${mockTemplatingDataResponses.simpleAndAdv}
    ${'Returns parsed object for all variable types'}                               | ${mockTemplatingData.allVariableTypes}        | ${mockTemplatingDataResponses.allVariableTypes}
  `('$case', ({ input, expected }) => {
    expect(parseTemplatingVariables(input?.dashboard?.templating)).toEqual(expected);
  });
});
