import { shallowMount } from '@vue/test-utils';
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

    const findFileLine = name => wrapper.find(name);
    const additions = findFileLine('.js-file-addition-line');
    const deletions = findFileLine('.js-file-deletion-line');

    expect(additions.text()).toBe('100');
    expect(deletions.text()).toBe('200');
  });
});
