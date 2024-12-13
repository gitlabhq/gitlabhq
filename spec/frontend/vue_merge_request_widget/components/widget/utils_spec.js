import { generateText } from '~/vue_merge_request_widget/components/widget/utils';

describe('generateText', () => {
  it.each`
    text                                                                       | expectedText
    ${'%{strong_start}Hello world%{strong_end}'}                               | ${'<span class="gl-font-bold">Hello world</span>'}
    ${'%{success_start}Hello world%{success_end}'}                             | ${'<span class="gl-font-bold gl-text-success">Hello world</span>'}
    ${'%{danger_start}Hello world%{danger_end}'}                               | ${'<span class="gl-font-bold gl-text-red-500">Hello world</span>'}
    ${'%{critical_start}Hello world%{critical_end}'}                           | ${'<span class="gl-font-bold gl-text-red-800">Hello world</span>'}
    ${'%{same_start}Hello world%{same_end}'}                                   | ${'<span class="gl-font-bold gl-text-gray-700">Hello world</span>'}
    ${'%{small_start}Hello world%{small_end}'}                                 | ${'<span class="gl-text-sm gl-text-gray-700">Hello world</span>'}
    ${'%{strong_start}%{danger_start}Hello world%{danger_end}%{strong_end}'}   | ${'<span class="gl-font-bold"><span class="gl-font-bold gl-text-red-500">Hello world</span></span>'}
    ${'%{no_exist_start}Hello world%{no_exist_end}'}                           | ${'Hello world'}
    ${{ text: 'Hello world', href: 'http://www.example.com' }}                 | ${'<a class="gl-underline" href="http://www.example.com">Hello world</a>'}
    ${{ prependText: 'Hello', text: 'world', href: 'http://www.example.com' }} | ${'Hello <a class="gl-underline" href="http://www.example.com">world</a>'}
    ${['array']}                                                               | ${null}
  `('generates $expectedText from $text', ({ text, expectedText }) => {
    expect(generateText(text)).toBe(expectedText);
  });
});
