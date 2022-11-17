import composerJsonLinker from '~/vue_shared/components/source_viewer/plugins/utils/composer_json_linker';
import { COMPOSER_JSON_EXAMPLES } from '../mock_data';

describe('Highlight.js plugin for linking composer.json dependencies', () => {
  it('mutates the input value by wrapping dependency names and versions in anchors', () => {
    const inputValue =
      '<span class="hljs-attr">&quot;drupal/erp_common"&quot;</span><span class="hljs-punctuation">:</span> <span class="hljs-string">&quot;dev-master&quot;</span>';
    const outputValue =
      '<span class="hljs-attr">&quot;drupal/erp_common"&quot;</span><span class="hljs-punctuation">:</span> <span class="hljs-string">&quot;dev-master&quot;</span>';
    const hljsResultMock = { value: inputValue };

    const output = composerJsonLinker(hljsResultMock, COMPOSER_JSON_EXAMPLES.withoutLink);
    expect(output).toBe(outputValue);
  });
});

const getInputValue = (dependencyString, version) =>
  `<span class="hljs-attr">&quot;${dependencyString}&quot;</span><span class="hljs-punctuation">:</span> <span class="hljs-string">&quot;${version}&quot;</span>`;
const getOutputValue = (dependencyString, version, expectedHref) =>
  `<span class="hljs-attr">&quot;<a href="${expectedHref}" target="_blank" rel="nofollow noreferrer noopener">${dependencyString}</a>&quot;</span>: <span class="hljs-attr">&quot;<a href="${expectedHref}" target="_blank" rel="nofollow noreferrer noopener">${version}</a>&quot;</span>`;

describe('Highlight.js plugin for linking Godeps.json dependencies', () => {
  it.each`
    type           | dependency               | version      | expectedHref
    ${'packagist'} | ${'composer/installers'} | ${'^1.2'}    | ${'https://packagist.org/packages/composer/installers'}
    ${'drupal'}    | ${'drupal/bootstrap'}    | ${'3.x-dev'} | ${'https://www.drupal.org/project/bootstrap'}
  `(
    'mutates the input value by wrapping dependency names in anchors and altering path when needed',
    ({ type, dependency, version, expectedHref }) => {
      const inputValue = getInputValue(dependency, version);
      const outputValue = getOutputValue(dependency, version, expectedHref);
      const hljsResultMock = { value: inputValue };

      const output = composerJsonLinker(hljsResultMock, COMPOSER_JSON_EXAMPLES[type]);
      expect(output).toBe(outputValue);
    },
  );
});
