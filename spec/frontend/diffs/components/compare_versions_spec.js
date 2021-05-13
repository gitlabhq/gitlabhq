import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { TEST_HOST } from 'helpers/test_constants';
import { trimText } from 'helpers/text_helper';
import CompareVersionsComponent from '~/diffs/components/compare_versions.vue';
import { createStore } from '~/mr_notes/stores';
import getDiffWithCommit from '../mock_data/diff_with_commit';
import diffsMockData from '../mock_data/merge_request_diffs';

const localVue = createLocalVue();
localVue.use(Vuex);

const NEXT_COMMIT_URL = `${TEST_HOST}/?commit_id=next`;
const PREV_COMMIT_URL = `${TEST_HOST}/?commit_id=prev`;

describe('CompareVersions', () => {
  let wrapper;
  let store;
  const targetBranchName = 'tmp-wine-dev';
  const { commit } = getDiffWithCommit();

  const createWrapper = (props = {}, commitArgs = {}, createCommit = true) => {
    if (createCommit) {
      store.state.diffs.commit = { ...store.state.diffs.commit, ...commitArgs };
    }

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
  const getCommitNavButtonsElement = () => wrapper.find('.commit-nav-buttons');
  const getNextCommitNavElement = () =>
    getCommitNavButtonsElement().find('.btn-group > *:last-child');
  const getPrevCommitNavElement = () =>
    getCommitNavButtonsElement().find('.btn-group > *:first-child');

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
      createWrapper({}, {}, false);
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

  describe('without neighbor commits', () => {
    beforeEach(() => {
      createWrapper({ commit: { ...commit, prev_commit_id: null, next_commit_id: null } });
    });

    it('does not render any navigation buttons', () => {
      expect(getCommitNavButtonsElement().exists()).toEqual(false);
    });
  });

  describe('with neighbor commits', () => {
    let mrCommit;

    beforeEach(() => {
      mrCommit = {
        ...commit,
        next_commit_id: 'next',
        prev_commit_id: 'prev',
      };

      createWrapper({}, mrCommit);
    });

    it('renders the commit navigation buttons', () => {
      expect(getCommitNavButtonsElement().exists()).toEqual(true);

      createWrapper({
        commit: { ...mrCommit, next_commit_id: null },
      });
      expect(getCommitNavButtonsElement().exists()).toEqual(true);

      createWrapper({
        commit: { ...mrCommit, prev_commit_id: null },
      });
      expect(getCommitNavButtonsElement().exists()).toEqual(true);
    });

    describe('prev commit', () => {
      beforeAll(() => {
        global.jsdom.reconfigure({
          url: `${TEST_HOST}?commit_id=${mrCommit.id}`,
        });
      });

      afterAll(() => {
        global.jsdom.reconfigure({
          url: TEST_HOST,
        });
      });

      beforeEach(() => {
        jest.spyOn(wrapper.vm, 'moveToNeighboringCommit').mockImplementation(() => {});
      });

      it('uses the correct href', () => {
        const link = getPrevCommitNavElement();

        expect(link.element.getAttribute('href')).toEqual(PREV_COMMIT_URL);
      });

      it('triggers the correct Vuex action on click', () => {
        const link = getPrevCommitNavElement();

        link.trigger('click');
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.vm.moveToNeighboringCommit).toHaveBeenCalledWith({
            direction: 'previous',
          });
        });
      });

      it('renders a disabled button when there is no prev commit', () => {
        createWrapper({}, { ...mrCommit, prev_commit_id: null });

        const button = getPrevCommitNavElement();

        expect(button.element.hasAttribute('disabled')).toEqual(true);
      });
    });

    describe('next commit', () => {
      beforeAll(() => {
        global.jsdom.reconfigure({
          url: `${TEST_HOST}?commit_id=${mrCommit.id}`,
        });
      });

      afterAll(() => {
        global.jsdom.reconfigure({
          url: TEST_HOST,
        });
      });

      beforeEach(() => {
        jest.spyOn(wrapper.vm, 'moveToNeighboringCommit').mockImplementation(() => {});
      });

      it('uses the correct href', () => {
        const link = getNextCommitNavElement();

        expect(link.element.getAttribute('href')).toEqual(NEXT_COMMIT_URL);
      });

      it('triggers the correct Vuex action on click', () => {
        const link = getNextCommitNavElement();

        link.trigger('click');
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.vm.moveToNeighboringCommit).toHaveBeenCalledWith({ direction: 'next' });
        });
      });

      it('renders a disabled button when there is no next commit', () => {
        createWrapper({}, { ...mrCommit, next_commit_id: null });

        const button = getNextCommitNavElement();

        expect(button.element.hasAttribute('disabled')).toEqual(true);
      });
    });
  });
});
