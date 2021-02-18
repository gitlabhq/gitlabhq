import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import DiffStats from '~/diffs/components/diff_stats.vue';

const TEST_ADDED_LINES = 100;
const TEST_REMOVED_LINES = 200;
const DIFF_FILES_COUNT = '300';
const DIFF_FILES_COUNT_TRUNCATED = '300+';

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

    it('is not rendered if diffFilesCountText is empty', () => {
      createComponent();

      expect(findDiffStatsGroup().length).toBe(2);
    });

    it('is not rendered if diffFilesCountText is not a number', () => {
      createComponent({
        diffFilesCountText: null,
      });

      expect(findDiffStatsGroup().length).toBe(2);
    });
  });

  describe('line changes', () => {
    const findFileLine = (name) => wrapper.find(name);

    it('shows the amount of lines added', () => {
      expect(findFileLine('.js-file-addition-line').text()).toBe(TEST_ADDED_LINES.toString());
    });

    it('shows the amount of lines removed', () => {
      expect(findFileLine('.js-file-deletion-line').text()).toBe(TEST_REMOVED_LINES.toString());
    });
  });

  describe('files changes', () => {
    const findIcon = (name) =>
      wrapper
        .findAll(GlIcon)
        .filter((c) => c.attributes('name') === name)
        .at(0).element.parentNode;

    it('shows amount of file changed with plural "files" when 0 files has changed', () => {
      const oneFileChanged = '0';

      createComponent({
        diffFilesCountText: oneFileChanged,
      });

      expect(findIcon('doc-code').textContent.trim()).toBe(`${oneFileChanged} files`);
    });

    it('shows amount of file changed with singular "file" when 1 file is changed', () => {
      const oneFileChanged = '1';

      createComponent({
        diffFilesCountText: oneFileChanged,
      });

      expect(findIcon('doc-code').textContent.trim()).toBe(`${oneFileChanged} file`);
    });

    it('shows amount of files change with plural "files" when multiple files are changed', () => {
      createComponent({
        diffFilesCountText: DIFF_FILES_COUNT,
      });

      expect(findIcon('doc-code').textContent.trim()).toContain(`${DIFF_FILES_COUNT} files`);
    });

    it('shows amount of files change with plural "files" when files changed is truncated', () => {
      createComponent({
        diffFilesCountText: DIFF_FILES_COUNT_TRUNCATED,
      });

      expect(findIcon('doc-code').textContent.trim()).toContain(
        `${DIFF_FILES_COUNT_TRUNCATED} files`,
      );
    });
  });
});
