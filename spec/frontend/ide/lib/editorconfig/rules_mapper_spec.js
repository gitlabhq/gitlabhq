import mapRulesToMonaco from '~/ide/lib/editorconfig/rules_mapper';

describe('mapRulesToMonaco', () => {
  const multipleEntries = {
    input: { indent_style: 'tab', indent_size: '4', insert_final_newline: 'true' },
    output: { insertSpaces: false, tabSize: 4, insertFinalNewline: true },
  };

  // tab width takes precedence
  const tabWidthAndIndent = {
    input: { indent_style: 'tab', indent_size: '4', tab_width: '3' },
    output: { insertSpaces: false, tabSize: 3 },
  };

  it.each`
    rule                                     | monacoOption
    ${{ indent_style: 'tab' }}               | ${{ insertSpaces: false }}
    ${{ indent_style: 'space' }}             | ${{ insertSpaces: true }}
    ${{ indent_style: 'unset' }}             | ${{}}
    ${{ indent_size: '4' }}                  | ${{ tabSize: 4 }}
    ${{ indent_size: '4.4' }}                | ${{ tabSize: 4 }}
    ${{ indent_size: '0' }}                  | ${{}}
    ${{ indent_size: '-10' }}                | ${{}}
    ${{ indent_size: 'NaN' }}                | ${{}}
    ${{ tab_width: '4' }}                    | ${{ tabSize: 4 }}
    ${{ tab_width: '5.4' }}                  | ${{ tabSize: 5 }}
    ${{ tab_width: '-10' }}                  | ${{}}
    ${{ trim_trailing_whitespace: 'true' }}  | ${{ trimTrailingWhitespace: true }}
    ${{ trim_trailing_whitespace: 'false' }} | ${{ trimTrailingWhitespace: false }}
    ${{ trim_trailing_whitespace: 'unset' }} | ${{}}
    ${{ end_of_line: 'lf' }}                 | ${{ endOfLine: 0 }}
    ${{ end_of_line: 'crlf' }}               | ${{ endOfLine: 1 }}
    ${{ end_of_line: 'cr' }}                 | ${{}}
    ${{ end_of_line: 'unset' }}              | ${{}}
    ${{ insert_final_newline: 'true' }}      | ${{ insertFinalNewline: true }}
    ${{ insert_final_newline: 'false' }}     | ${{ insertFinalNewline: false }}
    ${{ insert_final_newline: 'unset' }}     | ${{}}
    ${multipleEntries.input}                 | ${multipleEntries.output}
    ${tabWidthAndIndent.input}               | ${tabWidthAndIndent.output}
  `('correctly maps editorconfig rule to monaco option: $rule', ({ rule, monacoOption }) => {
    expect(mapRulesToMonaco(rule)).toEqual(monacoOption);
  });
});
