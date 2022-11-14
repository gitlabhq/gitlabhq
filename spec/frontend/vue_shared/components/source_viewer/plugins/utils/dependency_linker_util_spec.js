import {
  createLink,
  generateHLJSOpenTag,
  getObjectKeysByKeyName,
} from '~/vue_shared/components/source_viewer/plugins/utils/dependency_linker_util';
import { PODSPEC_JSON_CONTENT } from '../mock_data';

describe('createLink', () => {
  it('generates a link with the correct attributes', () => {
    const href = 'http://test.com';
    const innerText = 'testing';
    const result = `<a href="${href}" target="_blank" rel="nofollow noreferrer noopener">${innerText}</a>`;

    expect(createLink(href, innerText)).toBe(result);
  });

  it('escapes the user-controlled content', () => {
    const unescapedXSS = '<script>XSS</script>';
    const escapedPackageName = '&lt;script&gt;XSS&lt;/script&gt;';
    const escapedHref = '&lt;script&gt;XSS&lt;/script&gt;';
    const href = `http://test.com/${unescapedXSS}`;
    const innerText = `testing${unescapedXSS}`;
    const result = `<a href="http://test.com/${escapedHref}" target="_blank" rel="nofollow noreferrer noopener">testing${escapedPackageName}</a>`;

    expect(createLink(href, innerText)).toBe(result);
  });
});

describe('generateHLJSOpenTag', () => {
  it('generates an open tag with the correct selector', () => {
    const type = 'string';
    const result = `<span class="hljs-${type}">&quot;`;

    expect(generateHLJSOpenTag(type)).toBe(result);
  });
});

describe('getObjectKeysByKeyName method', () => {
  it('gets all object keys within specified key', () => {
    const acc = [];
    const keys = getObjectKeysByKeyName(JSON.parse(PODSPEC_JSON_CONTENT), 'dependencies', acc);
    expect(keys).toEqual(['MyCheckCore', 'AFNetworking/Security']);
  });
});
