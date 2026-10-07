import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import {
  CODE_SUGGESTIONS_OFF,
  getCodeSuggestionsConfig,
} from '~/rapid_diffs/utils/code_suggestions';

describe('getCodeSuggestionsConfig', () => {
  const diffRefs = { base_sha: 'base', start_sha: 'start', head_sha: 'head' };
  const blobRawPath = '/raw/file.rb';

  const newRow = (line, content) =>
    `<tr data-hunk-lines><td data-position="new"><a data-line-number="${line}"></a><pre>${content}</pre></td></tr>`;

  const textPosition = (range, extra = {}) => ({
    ...diffRefs,
    position_type: 'text',
    old_path: 'file.rb',
    new_path: 'file.rb',
    old_line: range.end.old_line,
    new_line: range.end.new_line,
    line_range: range,
    ...extra,
  });

  const newRange = (start, end) => ({
    start: { old_line: null, new_line: start },
    end: { old_line: null, new_line: end },
  });

  const resolve = (discussion, overrides = {}) =>
    getCodeSuggestionsConfig({
      discussion,
      diffElement: document.querySelector('table'),
      diffRefs,
      canReceiveSuggestion: true,
      blobRawPath,
      ...overrides,
    });

  beforeEach(() => {
    setHTMLFixture(
      `<table><tbody>${newRow(3, 'line three')}${newRow(4, 'line four')}${newRow(5, 'line five')}</tbody></table>`,
    );
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('resolves the lines, range and preview params for a thread on new lines', () => {
    expect(resolve({ position: textPosition(newRange(3, 5)) })).toEqual({
      canSuggest: true,
      lines: ['line three', 'line four', 'line five'],
      lineType: '',
      showPopover: false,
      blobRawPath,
      lineRange: { start: 3, end: 5 },
      previewParams: {
        preview_suggestions: true,
        line: 5,
        file_path: 'file.rb',
        ...diffRefs,
      },
    });
  });

  it('treats a position without a line range as a single line', () => {
    const position = textPosition(newRange(4, 4), { line_range: undefined });

    expect(resolve({ position })).toMatchObject({
      canSuggest: true,
      lines: ['line four'],
      lineRange: { start: 4, end: 4 },
    });
  });

  it('uses the position that applies to the diff on screen', () => {
    const discussion = {
      original_position: textPosition(newRange(3, 3), { head_sha: 'older' }),
      position: textPosition(newRange(5, 5)),
    };

    expect(resolve(discussion).lines).toEqual(['line five']);
  });

  it.each`
    scenario                                      | discussion                                                                                                      | overrides
    ${'the noteable does not accept suggestions'} | ${{ position: textPosition(newRange(3, 5)) }}                                                                   | ${{ canReceiveSuggestion: false }}
    ${'there is no discussion'}                   | ${null}                                                                                                         | ${{}}
    ${'the page has no diff refs'}                | ${{ position: textPosition(newRange(3, 5)) }}                                                                   | ${{ diffRefs: undefined }}
    ${'no position applies to the shown diff'}    | ${{ position: textPosition(newRange(3, 5), { head_sha: 'old' }) }}                                              | ${{}}
    ${'the position is not on text'}              | ${{ position: textPosition(newRange(3, 5), { position_type: 'image' }) }}                                       | ${{}}
    ${'the range ends on a removed line'}         | ${{ position: textPosition({ start: { old_line: 3, new_line: null }, end: { old_line: 3, new_line: null } }) }} | ${{}}
    ${'part of the range is not rendered'}        | ${{ position: textPosition(newRange(3, 7)) }}                                                                   | ${{}}
  `('turns suggestions off when $scenario', ({ discussion, overrides }) => {
    expect(resolve(discussion, overrides)).toBe(CODE_SUGGESTIONS_OFF);
  });
});
