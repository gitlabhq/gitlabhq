import {
  markInputRegex,
  extractMarkAttributesFromMatch,
} from '~/content_editor/services/mark_utils';

describe('content_editor/services/mark_utils', () => {
  describe.each`
    tag       | input                                                               | matches
    ${'tag'}  | ${'<tag>hello</tag>'}                                               | ${true}
    ${'tag'}  | ${'<tag title="tooltip">hello</tag>'}                               | ${true}
    ${'kbd'}  | ${'Hold <kbd>Ctrl</kbd>'}                                           | ${true}
    ${'time'} | ${'Lets meet at <time title="today" datetime="20:00">20:00</time>'} | ${true}
    ${'tag'}  | ${'<tag width=30 height=30>attrs not quoted</tag>'}                 | ${false}
    ${'tag'}  | ${"<tag title='abc'>single quote attrs not supported</tag>"}        | ${false}
    ${'tag'}  | ${'<tag title>attr has no value</tag>'}                             | ${false}
    ${'tag'}  | ${'<tag>tag opened but not closed'}                                 | ${false}
    ${'tag'}  | ${'</tag>tag closed before opened<tag>'}                            | ${false}
  `('inputRegex("$tag")', ({ tag, input, matches }) => {
    it(`${matches ? 'matches' : 'does not match'}: "${input}"`, () => {
      const match = markInputRegex(tag).test(input);

      expect(match).toBe(matches);
    });
  });

  describe.each`
    tag       | input                                                                             | attrs
    ${'kbd'}  | ${'Hold <kbd>Ctrl</kbd>'}                                                         | ${{}}
    ${'tag'}  | ${'<tag title="tooltip">hello</tag>'}                                             | ${{ title: 'tooltip' }}
    ${'time'} | ${'Lets meet at <time title="today" datetime="20:00">20:00</time>'}               | ${{ title: 'today', datetime: '20:00' }}
    ${'abbr'} | ${'Sure, you can try it out but <abbr title="Your mileage may vary">YMMV</abbr>'} | ${{ title: 'Your mileage may vary' }}
  `('extractAttributesFromMatch(inputRegex("$tag").exec(\'$input\'))', ({ tag, input, attrs }) => {
    it(`returns: "${JSON.stringify(attrs)}"`, () => {
      const matches = markInputRegex(tag).exec(input);
      expect(extractMarkAttributesFromMatch(matches)).toEqual(attrs);
    });
  });
});
