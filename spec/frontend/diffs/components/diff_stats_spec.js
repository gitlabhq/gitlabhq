import { shallowMount } from '@vue/test-utils';
import DiffStats from '~/diffs/components/diff_stats.vue';
import Icon from '~/vue_shared/components/icon.vue';

describe('diff_stats', () => {
  it('does not render a group if diffFileLengths is empty', () => {
    const wrapper = shallowMount(DiffStats, {
      propsData: {
        addedLines: 1,
        removedLines: 2,
      },
    });
    const groups = wrapper.findAll('.diff-stats-group');

    expect(groups.length).toBe(2);
  });

  it('does not render a group if diffFileLengths is not a number', () => {
    const wrapper = shallowMount(DiffStats, {
      propsData: {
        addedLines: 1,
        removedLines: 2,
        diffFilesLength: Number.NaN,
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

    const findFileLine = name => wrapper.find(name);
    const findIcon = name =>
      wrapper
        .findAll(Icon)
        .filter(c => c.attributes('name') === name)
        .at(0).element.parentNode;
    const additions = findFileLine('.js-file-addition-line');
    const deletions = findFileLine('.js-file-deletion-line');
    const filesChanged = findIcon('doc-code');

    expect(additions.text()).toBe('100');
    expect(deletions.text()).toBe('200');
    expect(filesChanged.textContent).toContain('300');
  });
});
