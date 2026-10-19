import cartfileLinker from '~/highlight_js/plugins/utils/cartfile_linker';

describe('Highlight.js plugin for linking Cartfile dependencies', () => {
  const link = (text, href) =>
    `<a href="${href}" target="_blank" rel="nofollow noreferrer noopener">${text}</a>`;

  it('links github origins to the repository on GitHub', () => {
    const inputValue =
      '<span class="">github &quot;ReactiveCocoa/ReactiveCocoa&quot; &gt;= 2.3.1</span>\n<span class="">github &quot;Mantle/Mantle&quot; ~&gt; 1.0</span>';
    const outputValue =
      `<span class="">github &quot;${link('ReactiveCocoa/ReactiveCocoa', 'https://github.com/ReactiveCocoa/ReactiveCocoa')}&quot; &gt;= 2.3.1</span>\n` +
      `<span class="">github &quot;${link('Mantle/Mantle', 'https://github.com/Mantle/Mantle')}&quot; ~&gt; 1.0</span>`;

    expect(cartfileLinker({ value: inputValue })).toBe(outputValue);
  });

  it('links git, binary and github URL origins to the URL itself', () => {
    const gitUrl = 'https://enterprise.local/desktop/git-error-translations2.git';
    const binaryUrl = 'https://my.domain.com/release/MyFramework.json';
    const githubUrl = 'https://enterprise.local/project/repo';
    const inputValue =
      `<span class="">git &quot;${gitUrl}&quot;</span>\n` +
      `<span class="">binary &quot;${binaryUrl}&quot; ~&gt; 2.3</span>\n` +
      `<span class="">github &quot;${githubUrl}&quot;</span>`;
    const outputValue =
      `<span class="">git &quot;${link(gitUrl, gitUrl)}&quot;</span>\n` +
      `<span class="">binary &quot;${link(binaryUrl, binaryUrl)}&quot; ~&gt; 2.3</span>\n` +
      `<span class="">github &quot;${link(githubUrl, githubUrl)}&quot;</span>`;

    expect(cartfileLinker({ value: inputValue })).toBe(outputValue);
  });

  it('links indented and aligned origins', () => {
    const inputValue =
      '<span class="">  github &quot;Owner/Repo&quot;</span>\n' +
      '<span class="">github   &quot;Other/Repo&quot;</span>';
    const outputValue =
      `<span class="">  github &quot;${link('Owner/Repo', 'https://github.com/Owner/Repo')}&quot;</span>\n` +
      `<span class="">github   &quot;${link('Other/Repo', 'https://github.com/Other/Repo')}&quot;</span>`;

    expect(cartfileLinker({ value: inputValue })).toBe(outputValue);
  });

  it('keeps an escaped query string inside the URL', () => {
    const url = 'https://my.domain.com/release/MyFramework.json?a=1&amp;b=2';
    const inputValue = `<span class="">binary &quot;${url}&quot;</span>`;

    expect(cartfileLinker({ value: inputValue })).toBe(
      `<span class="">binary &quot;${link(url, url)}&quot;</span>`,
    );
  });

  it('does not link comments or unknown keywords', () => {
    const inputValue =
      '<span class=""># github &quot;Owner/Repo&quot;</span>\n<span class="">local &quot;Owner/Repo&quot;</span>';

    expect(cartfileLinker({ value: inputValue })).toBe(inputValue);
  });
});
