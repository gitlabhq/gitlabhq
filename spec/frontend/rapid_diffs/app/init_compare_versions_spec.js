import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { initCompareVersions } from '~/rapid_diffs/app/init_compare_versions';

jest.mock('~/rapid_diffs/app/compare_versions/compare_versions.vue', () => ({
  name: 'CompareVersions',
  props: ['sourceVersions', 'targetVersions'],
  render(h) {
    return h('div', {
      attrs: {
        'data-compare-versions': 'true',
        'data-source-versions': JSON.stringify(this.sourceVersions),
        'data-target-versions': JSON.stringify(this.targetVersions),
      },
    });
  },
}));

describe('initCompareVersions', () => {
  const sourceVersions = [
    { id: 1, version_index: 1, latest: true, selected: true },
    { id: 2, version_index: 2, latest: false, selected: false },
  ];

  const targetVersions = [
    { id: 'head', version_index: null, head: true, selected: true, branch: 'main' },
  ];

  const appData = {
    versions: { source_versions: sourceVersions, target_versions: targetVersions },
  };

  const findCompareVersions = () => document.querySelector('[data-compare-versions]');

  afterEach(() => {
    resetHTMLFixture();
  });

  it('renders CompareVersions component', () => {
    setHTMLFixture('<div data-after-browser-toggle></div>');

    const el = document.querySelector('[data-after-browser-toggle]');
    initCompareVersions(el, appData);

    expect(findCompareVersions()).not.toBeNull();
  });

  it('passes sourceVersions prop to component', () => {
    setHTMLFixture('<div data-after-browser-toggle></div>');

    const el = document.querySelector('[data-after-browser-toggle]');
    initCompareVersions(el, appData);

    const component = findCompareVersions();
    expect(JSON.parse(component.dataset.sourceVersions)).toEqual(sourceVersions);
  });

  it('passes targetVersions prop to component', () => {
    setHTMLFixture('<div data-after-browser-toggle></div>');

    const el = document.querySelector('[data-after-browser-toggle]');
    initCompareVersions(el, appData);

    const component = findCompareVersions();
    expect(JSON.parse(component.dataset.targetVersions)).toEqual(targetVersions);
  });
});
