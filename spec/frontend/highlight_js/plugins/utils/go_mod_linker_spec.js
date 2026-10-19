import goModLinker from '~/highlight_js/plugins/utils/go_mod_linker';

describe('Highlight.js plugin for linking go.mod dependencies', () => {
  const link = (modulePath, version) => {
    const href = version
      ? `https://pkg.go.dev/${modulePath}@${version}`
      : `https://pkg.go.dev/${modulePath}`;
    return `<a href="${href}" target="_blank" rel="nofollow noreferrer noopener">${modulePath}</a>`;
  };

  it('links required modules to their version on pkg.go.dev', () => {
    const inputValue =
      '<span class="">require (</span>\n' +
      '<span class="">\tgithub.com/BurntSushi/toml v0.3.1</span>\n' +
      '<span class="">\tgitlab.com/gitlab-org/labkit v1.3.0 // indirect</span>\n' +
      '<span class="">\tgolang.org/x/net v0.0.0-20220127200216-cd36cc0744dd</span>\n' +
      '<span class="">)</span>\n' +
      '<span class="">require github.com/stretchr/testify v1.8.0</span>';
    const outputValue =
      '<span class="">require (</span>\n' +
      `<span class="">\t${link('github.com/BurntSushi/toml', 'v0.3.1')} v0.3.1</span>\n` +
      `<span class="">\t${link('gitlab.com/gitlab-org/labkit', 'v1.3.0')} v1.3.0 // indirect</span>\n` +
      `<span class="">\t${link('golang.org/x/net', 'v0.0.0-20220127200216-cd36cc0744dd')} v0.0.0-20220127200216-cd36cc0744dd</span>\n` +
      '<span class="">)</span>\n' +
      `<span class="">require ${link('github.com/stretchr/testify', 'v1.8.0')} v1.8.0</span>`;

    expect(goModLinker({ value: inputValue })).toBe(outputValue);
  });

  it('links the module and replace directives without a version', () => {
    const inputValue =
      '<span class="">module gitlab.com/gitlab-org/gitlab-workhorse</span>\n' +
      '<span class="">replace github.com/foo/bar =&gt; ../bar</span>';
    const outputValue =
      `<span class="">module ${link('gitlab.com/gitlab-org/gitlab-workhorse')}</span>\n` +
      `<span class="">replace ${link('github.com/foo/bar')} =&gt; ../bar</span>`;

    expect(goModLinker({ value: inputValue })).toBe(outputValue);
  });

  it('links the tool directive and keywords separated by a tab', () => {
    const inputValue =
      '<span class="">tool golang.org/x/tools/cmd/stringer</span>\n' +
      '<span class="">require\tgithub.com/foo/bar v1.0.0</span>\n' +
      '<span class="">tool (</span>\n' +
      '<span class="">\tgolang.org/x/tools/cmd/goimports</span>\n' +
      '<span class="">)</span>';
    const outputValue =
      `<span class="">tool ${link('golang.org/x/tools/cmd/stringer')}</span>\n` +
      `<span class="">require\t${link('github.com/foo/bar', 'v1.0.0')} v1.0.0</span>\n` +
      '<span class="">tool (</span>\n' +
      `<span class="">\t${link('golang.org/x/tools/cmd/goimports')}</span>\n` +
      '<span class="">)</span>';

    expect(goModLinker({ value: inputValue })).toBe(outputValue);
  });

  it('keeps a tab between the module path and version in the link', () => {
    const inputValue = '<span class="">require github.com/foo/bar\tv1.0.0</span>';
    const outputValue = `<span class="">require ${link('github.com/foo/bar', 'v1.0.0')}\tv1.0.0</span>`;

    expect(goModLinker({ value: inputValue })).toBe(outputValue);
  });

  it('does not link directives without a module path', () => {
    const inputValue = '<span class="">go 1.17</span>\n<span class="">toolchain go1.21.0</span>';

    expect(goModLinker({ value: inputValue })).toBe(inputValue);
  });
});
