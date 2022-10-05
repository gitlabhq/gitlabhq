import wrapBidiChars from '~/vue_shared/components/source_viewer/plugins/wrap_bidi_chars';
import {
  BIDI_CHARS,
  BIDI_CHARS_CLASS_LIST,
  BIDI_CHAR_TOOLTIP,
} from '~/vue_shared/components/source_viewer/constants';

describe('Highlight.js plugin for wrapping BiDi characters', () => {
  it.each(BIDI_CHARS)('wraps %s BiDi char', (bidiChar) => {
    const inputValue = `// some content ${bidiChar} with BiDi chars`;
    const outputValue = `// some content <span class="${BIDI_CHARS_CLASS_LIST}" title="${BIDI_CHAR_TOOLTIP}">${bidiChar}</span>`;
    const hljsResultMock = { value: inputValue };

    wrapBidiChars(hljsResultMock);
    expect(hljsResultMock.value).toContain(outputValue);
  });
});
