describe('custom matcher toMatchInterpolatedText', () => {
  describe('malformed input', () => {
    it.each([null, 1, Symbol, Array, Object])(
      'fails graciously if the expected value is %s',
      (expected) => {
        expect(expected).not.toMatchInterpolatedText('null');
      },
    );
  });
  describe('malformed matcher', () => {
    it.each([null, 1, Symbol, Array, Object])(
      'fails graciously if the matcher is %s',
      (matcher) => {
        expect('null').not.toMatchInterpolatedText(matcher);
      },
    );
  });

  describe('positive assertion', () => {
    it.each`
      htmlString         | templateString
      ${'foo'}           | ${'foo'}
      ${'foo'}           | ${'foo%{foo}'}
      ${'foo  '}         | ${'foo'}
      ${'foo  '}         | ${'foo%{foo}'}
      ${'foo   . '}      | ${'foo%{foo}.'}
      ${'foo   bar . '}  | ${'foo%{foo} bar.'}
      ${'foo\n\nbar . '} | ${'foo%{foo} bar.'}
      ${'foo bar . .'}   | ${'foo%{fooStart} bar.%{fooEnd}.'}
    `('$htmlString equals $templateString', ({ htmlString, templateString }) => {
      expect(htmlString).toMatchInterpolatedText(templateString);
    });
  });

  describe('negative assertion', () => {
    it.each`
      htmlString  | templateString
      ${'foo'}    | ${'bar'}
      ${'foo'}    | ${'bar%{foo}'}
      ${'foo'}    | ${'@{lol}foo%{foo}'}
      ${' fo o '} | ${'foo'}
    `('$htmlString does not equal $templateString', ({ htmlString, templateString }) => {
      expect(htmlString).not.toMatchInterpolatedText(templateString);
    });
  });
});
