import { trimText } from 'helpers/text_helper';
import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import CompareVersionsComponent from '~/diffs/components/compare_versions.vue';
import { createStore } from '~/mr_notes/stores';
import diffsMockData from '../mock_data/merge_request_diffs';
import getDiffWithCommit from '../mock_data/diff_with_commit';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('CompareVersions', () => {
  let wrapper;
  let store;
  const targetBranchName = 'tmp-wine-dev';

  const createWrapper = (props) => {
    wrapper = mount(CompareVersionsComponent, {
      localVue,
      store,
      propsData: {
        mergeRequestDiffs: diffsMockData,
        diffFilesCountText: '1',
        ...props,
      },
    });
  };
  const findLimitedContainer = () => wrapper.find('.container-limited.limit-container-width');
  const findCompareSourceDropdown = () => wrapper.find('.mr-version-dropdown');
  const findCompareTargetDropdown = () => wrapper.find('.mr-version-compare-dropdown');

  beforeEach(() => {
    store = createStore();
    const mergeRequestDiff = diffsMockData[0];

    store.state.diffs.addedLines = 10;
    store.state.diffs.removedLines = 20;
    store.state.diffs.diffFiles.push('test');
    store.state.diffs.targetBranchName = targetBranchName;
    store.state.diffs.mergeRequestDiff = mergeRequestDiff;
    store.state.diffs.mergeRequestDiffs = diffsMockData;
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('template', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render Tree List toggle button with correct attribute values', () => {
      const treeListBtn = wrapper.find('.js-toggle-tree-list');

      expect(treeListBtn.exists()).toBe(true);
      expect(treeListBtn.attributes('title')).toBe('Hide file browser');
      expect(treeListBtn.props('icon')).toBe('file-tree');
    });

    it('should render comparison dropdowns with correct values', () => {
      const sourceDropdown = findCompareSourceDropdown();
      const targetDropdown = findCompareTargetDropdown();

      expect(sourceDropdown.exists()).toBe(true);
      expect(targetDropdown.exists()).toBe(true);
      expect(sourceDropdown.find('a p').html()).toContain('latest version');
      expect(targetDropdown.find('button').html()).toContain(targetBranchName);
    });

    it('should render view types buttons with correct values', () => {
      const inlineBtn = wrapper.find('#inline-diff-btn');
      const parallelBtn = wrapper.find('#parallel-diff-btn');

      expect(inlineBtn.exists()).toBe(true);
      expect(parallelBtn.exists()).toBe(true);
      expect(inlineBtn.attributes('data-view-type')).toEqual('inline');
      expect(parallelBtn.attributes('data-view-type')).toEqual('parallel');
      expect(inlineBtn.html()).toContain('Inline');
      expect(parallelBtn.html()).toContain('Side-by-side');
    });

    it('adds container-limiting classes when showFileTree is false with inline diffs', () => {
      createWrapper({ isLimitedContainer: true });

      expect(findLimitedContainer().exists()).toBe(true);
    });

    it('does not add container-limiting classes when showFileTree is false with inline diffs', () => {
      createWrapper({ isLimitedContainer: false });

      expect(findLimitedContainer().exists()).toBe(false);
    });
  });

  describe('noChangedFiles', () => {
    beforeEach(() => {
      store.state.diffs.diffFiles = [];
    });

    it('should not render Tree List toggle button when there are no changes', () => {
      createWrapper();

      const treeListBtn = wrapper.find('.js-toggle-tree-list');

      expect(treeListBtn.exists()).toBe(false);
    });
  });

  describe('setInlineDiffViewType', () => {
    it('should persist the view type in the url', () => {
      createWrapper();

      const viewTypeBtn = wrapper.find('#inline-diff-btn');
      viewTypeBtn.trigger('click');

      expect(window.location.toString()).toContain('?view=inline');
    });
  });

  describe('setParallelDiffViewType', () => {
    it('should persist the view type in the url', () => {
      createWrapper();
      const viewTypeBtn = wrapper.find('#parallel-diff-btn');
      viewTypeBtn.trigger('click');

      expect(window.location.toString()).toContain('?view=parallel');
    });
  });

  describe('commit', () => {
    beforeEach(() => {
      store.state.diffs.commit = getDiffWithCommit().commit;
      createWrapper();
    });

    it('does not render compare dropdowns', () => {
      expect(findCompareSourceDropdown().exists()).toBe(false);
      expect(findCompareTargetDropdown().exists()).toBe(false);
    });

    it('renders latest version button', () => {
      expect(trimText(wrapper.find('.js-latest-version').text())).toBe('Show latest version');
    });

    it('renders short commit ID', () => {
      expect(wrapper.text()).toContain('Viewing commit');
      expect(wrapper.text()).toContain(wrapper.vm.commit.short_id);
    });
  });

  describe('with no versions', () => {
    beforeEach(() => {
      store.state.diffs.mergeRequestDiffs = [];
      createWrapper();
    });

    it('does not render compare dropdowns', () => {
      expect(findCompareSourceDropdown().exists()).toBe(false);
      expect(findCompareTargetDropdown().exists()).toBe(false);
    });
  });
});
