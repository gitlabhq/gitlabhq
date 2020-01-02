import { shallowMount } from '@vue/test-utils';
import Icon from '~/vue_shared/components/icon.vue';
import DiffStats from '~/diffs/components/diff_stats.vue';

describe('diff_stats', () => {
  it('does not render a group if diffFileLengths is not passed in', () => {
    const wrapper = shallowMount(DiffStats, {
      propsData: {
        addedLines: 1,
        removedLines: 2,
      },
    });
    const groups = wrapper.findAll('.diff-stats-group');

    expect(groups.length).toBe(2);
  });

  it('shows amount of files changed, lines added and lines removed when passed all props', () => {
    const wrapper = shallowMount(DiffStats, {
      propsData: {
        addedLines: 100,
        removedLines: 200,
        diffFilesLength: 300,
      },
    });

    const findIcon = name =>
      wrapper
        .findAll(Icon)
        .filter(c => c.attributes('name') === name)
        .at(0).element.parentNode;

    const additions = findIcon('file-addition');
    const deletions = findIcon('file-deletion');
    const filesChanged = findIcon('doc-code');

    expect(additions.textContent).toContain('100');
    expect(deletions.textContent).toContain('200');
    expect(filesChanged.textContent).toContain('300');
  });
});
