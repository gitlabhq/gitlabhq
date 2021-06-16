import sanitizeHTML from '~/static_site_editor/rich_content_editor/services/sanitize_html';

describe('rich_content_editor/services/sanitize_html', () => {
  it.each`
    input                                                | result
    ${'<iframe src="https://www.youtube.com"></iframe>'} | ${'<iframe src="https://www.youtube.com"></iframe>'}
    ${'<iframe src="https://gitlab.com"></iframe>'}      | ${''}
  `('removes iframes if the iframe source origin is not allowed', ({ input, result }) => {
    expect(sanitizeHTML(input)).toBe(result);
  });
});
