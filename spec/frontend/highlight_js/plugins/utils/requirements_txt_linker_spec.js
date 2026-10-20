import requirementsTxtLinker from '~/highlight_js/plugins/utils/requirements_txt_linker';

describe('Highlight.js plugin for linking requirements.txt dependencies', () => {
  const link = (text, href) =>
    `<a href="${href}" target="_blank" rel="nofollow noreferrer noopener">${text}</a>`;
  const pypi = (name) => link(name, `https://pypi.org/project/${name}/`);

  it('links package names to their page on PyPI', () => {
    const inputValue =
      '<span class="">Django==3.2</span>\n' +
      '<span class="">requests&gt;=2.0,&lt;3</span>\n' +
      '<span class="">numpy [security] &gt;= 1.0</span>\n' +
      '<span class="">pytest-cov~=4.0; python_version &gt;= &quot;3.8&quot;</span>\n' +
      '<span class="">flask</span>';
    const outputValue =
      `<span class="">${pypi('Django')}==3.2</span>\n` +
      `<span class="">${pypi('requests')}&gt;=2.0,&lt;3</span>\n` +
      `<span class="">${pypi('numpy')} [security] &gt;= 1.0</span>\n` +
      `<span class="">${pypi('pytest-cov')}~=4.0; python_version &gt;= &quot;3.8&quot;</span>\n` +
      `<span class="">${pypi('flask')}</span>`;

    expect(requirementsTxtLinker({ value: inputValue })).toBe(outputValue);
  });

  it('links URL lines to the URL itself', () => {
    const url = 'https://example.com/pkg.tar.gz';
    const inputValue = `<span class="">${url}</span>`;

    expect(requirementsTxtLinker({ value: inputValue })).toBe(
      `<span class="">${link(url, url)}</span>`,
    );
  });

  it('keeps an escaped query string inside the URL', () => {
    const url = 'https://example.com/pkg.tar.gz?a=1&amp;b=2';
    const inputValue = `<span class="">${url}</span>`;

    expect(requirementsTxtLinker({ value: inputValue })).toBe(
      `<span class="">${link(url, url)}</span>`,
    );
  });

  it('links only the package name when a direct reference URL follows with @', () => {
    const inputValue = '<span class="">pkg@https://example.com/pkg.whl</span>';

    expect(requirementsTxtLinker({ value: inputValue })).toBe(
      `<span class="">${pypi('pkg')}@https://example.com/pkg.whl</span>`,
    );
  });

  it('does not link comments, options, paths, relative wheels or VCS references', () => {
    const inputValue =
      '<span class=""># a comment</span>\n' +
      '<span class="">-e git+https://github.com/x/y.git#egg=y</span>\n' +
      '<span class="">--index-url https://pypi.example.org/simple</span>\n' +
      '<span class="">./vendor/package</span>\n' +
      '<span class="">vendor/pkg.whl</span>\n' +
      '<span class="">git+https://github.com/x/y.git</span>';

    expect(requirementsTxtLinker({ value: inputValue })).toBe(inputValue);
  });
});
