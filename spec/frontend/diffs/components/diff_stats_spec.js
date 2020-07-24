import { shallowMount } from '@vue/test-utils';
import DiffStats from '~/diffs/components/diff_stats.vue';
import Icon from '~/vue_shared/components/icon.vue';

const TEST_ADDED_LINES = 100;
const TEST_REMOVED_LINES = 200;
const DIFF_FILES_LENGTH = 300;

describe('diff_stats', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(DiffStats, {
      propsData: {
        addedLines: TEST_ADDED_LINES,
        removedLines: TEST_REMOVED_LINES,
        ...props,
      },
    });
  };

  describe('diff stats group', () => {
    const findDiffStatsGroup = () => wrapper.findAll('.diff-stats-group');

    it('is not rendered if diffFileLengths is empty', () => {
      createComponent();

      expect(findDiffStatsGroup().length).toBe(2);
    });

    it('is not rendered if diffFileLengths is not a number', () => {
      createComponent({
        diffFilesLength: Number.NaN,
      });

      expect(findDiffStatsGroup().length).toBe(2);
    });
  });

  describe('amount displayed', () => {
    beforeEach(() => {
      createComponent({
        diffFilesLength: DIFF_FILES_LENGTH,
      });
    });

    const findFileLine = name => wrapper.find(name);
    const findIcon = name =>
      wrapper
        .findAll(Icon)
        .filter(c => c.attributes('name') === name)
        .at(0).element.parentNode;

    it('shows the amount of lines added', () => {
      expect(findFileLine('.js-file-addition-line').text()).toBe(TEST_ADDED_LINES.toString());
    });

    it('shows the amount of lines removed', () => {
      expect(findFileLine('.js-file-deletion-line').text()).toBe(TEST_REMOVED_LINES.toString());
    });

    it('shows the amount of files changed', () => {
      expect(findIcon('doc-code').textContent).toContain(DIFF_FILES_LENGTH);
    });
  });
});
