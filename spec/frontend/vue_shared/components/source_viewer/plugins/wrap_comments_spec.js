import { HLJS_COMMENT_SELECTOR } from '~/vue_shared/components/source_viewer/constants';
import wrapComments from '~/vue_shared/components/source_viewer/plugins/wrap_comments';

describe('Highlight.js plugin for wrapping comments', () => {
  it('mutates the input value by wrapping each line in a span tag', () => {
    const inputValue = `<span class="${HLJS_COMMENT_SELECTOR}">/* Line 1 \n* Line 2 \n*/</span>`;
    const outputValue = `<span class="${HLJS_COMMENT_SELECTOR}">/* Line 1 \n<span class="${HLJS_COMMENT_SELECTOR}">* Line 2 </span>\n<span class="${HLJS_COMMENT_SELECTOR}">*/</span>`;
    const hljsResultMock = { value: inputValue };

    wrapComments(hljsResultMock);
    expect(hljsResultMock.value).toBe(outputValue);
  });

  it('does not mutate the input value if the hljs comment selector is not present', () => {
    const inputValue = '<span class="hljs-keyword">const</span>';
    const hljsResultMock = { value: inputValue };

    wrapComments(hljsResultMock);
    expect(hljsResultMock.value).toBe(inputValue);
  });

  it('does not mutate the input value if the hljs comment line includes a closing tag', () => {
    const inputValue = `<span class="${HLJS_COMMENT_SELECTOR}">/* Line 1 </span> \n* Line 2 \n*/`;
    const hljsResultMock = { value: inputValue };

    wrapComments(hljsResultMock);
    expect(hljsResultMock.value).toBe(inputValue);
  });
});
