import { GlAnimatedSidebarIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import getDiffWithCommit from 'test_fixtures/merge_request_diffs/with_commit.json';
import setWindowLocation from 'helpers/set_window_location_helper';
import { TEST_HOST } from 'helpers/test_constants';
import { trimText } from 'helpers/text_helper';
import CompareVersionsComponent from '~/diffs/components/compare_versions.vue';
import store from '~/mr_notes/stores';
import diffsMockData from '../mock_data/merge_request_diffs';

jest.mock('~/mr_notes/stores', () => jest.requireActual('helpers/mocks/mr_notes/stores'));

const NEXT_COMMIT_URL = `${TEST_HOST}/?commit_id=next`;
const PREV_COMMIT_URL = `${TEST_HOST}/?commit_id=prev`;

beforeEach(() => {
  setWindowLocation(TEST_HOST);
});

describe('CompareVersions', () => {
  let wrapper;
  const targetBranchName = 'tmp-wine-dev';
  const { commit } = getDiffWithCommit;

  const createWrapper = ({ props = {}, commitArgs = {}, createCommit = true } = {}) => {
    if (createCommit) {
      store.state.diffs.commit = { ...store.state.diffs.commit, ...commitArgs };
    }

    wrapper = mount(CompareVersionsComponent, {
      propsData: {
        toggleFileTreeVisible: true,
        ...props,
      },
      mocks: {
        $store: store,
      },
    });
  };
  const findCompareSourceDropdown = () => wrapper.find('.mr-version-dropdown');
  const findCompareTargetDropdown = () => wrapper.find('.mr-version-compare-dropdown');
  const getCommitNavButtonsElement = () => wrapper.find('.commit-nav-buttons');
  const getNextCommitNavElement = () =>
    getCommitNavButtonsElement().find('.btn-group > *:last-child');
  const getPrevCommitNavElement = () =>
    getCommitNavButtonsElement().find('.btn-group > *:first-child');

  beforeEach(() => {
    store.reset();

    const mergeRequestDiff = diffsMockData[0];
    const version = {
      ...mergeRequestDiff,
      href: `${TEST_HOST}/latest/version`,
      versionName: 'latest version',
    };
    store.getters['diffs/diffCompareDropdownSourceVersions'] = [version];
    store.getters['diffs/diffCompareDropdownTargetVersions'] = [
      {
        ...version,
        selected: true,
        versionName: targetBranchName,
      },
    ];
    store.getters['diffs/whichCollapsedTypes'] = { any: false };
    store.getters['diffs/isInlineView'] = false;
    store.getters['diffs/isParallelView'] = false;

    store.state.diffs.addedLines = 10;
    store.state.diffs.removedLines = 20;
    store.state.diffs.diffFiles.push('test');
    store.state.diffs.targetBranchName = targetBranchName;
    store.state.diffs.mergeRequestDiff = mergeRequestDiff;
    store.state.diffs.mergeRequestDiffs = diffsMockData;
  });

  describe('template', () => {
    beforeEach(() => {
      createWrapper({ createCommit: false });
    });

    it('should render Tree List toggle button with correct attribute values', () => {
      const treeListBtn = wrapper.find('.js-toggle-tree-list');

      expect(treeListBtn.exists()).toBe(true);
      expect(treeListBtn.attributes('aria-label')).toBe('Hide file browser');
      expect(treeListBtn.findComponent(GlAnimatedSidebarIcon).exists()).toBe(true);
    });

    it('should render comparison dropdowns with correct values', () => {
      const sourceDropdown = findCompareSourceDropdown();
      const targetDropdown = findCompareTargetDropdown();

      expect(sourceDropdown.exists()).toBe(true);
      expect(targetDropdown.exists()).toBe(true);
      expect(sourceDropdown.find('a p').html()).toContain('latest version');
      expect(targetDropdown.find('button').html()).toContain(targetBranchName);
    });
  });

  it('should not render Tree List toggle button when a prop is false', () => {
    createWrapper({ props: { toggleFileTreeVisible: false } });
    const treeListBtn = wrapper.find('.js-toggle-tree-list');

    expect(treeListBtn.exists()).toBe(false);
  });

  describe('commit', () => {
    beforeEach(() => {
      store.state.diffs.commit = commit;
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
      expect(wrapper.text()).toContain(commit.short_id);
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
      createWrapper({ commitArgs: { ...commit, prev_commit_id: null, next_commit_id: null } });
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

      createWrapper({ commitArgs: mrCommit });
    });

    it('renders the commit navigation buttons', () => {
      expect(getCommitNavButtonsElement().exists()).toEqual(true);

      createWrapper({ commitArgs: { ...mrCommit, next_commit_id: null } });
      expect(getCommitNavButtonsElement().exists()).toEqual(true);

      createWrapper({ commitArgs: { ...mrCommit, prev_commit_id: null } });
      expect(getCommitNavButtonsElement().exists()).toEqual(true);
    });

    describe('prev commit', () => {
      beforeAll(() => {
        setWindowLocation(`?commit_id=${mrCommit.id}`);
      });

      it('uses the correct href', () => {
        const link = getPrevCommitNavElement();

        expect(link.element.getAttribute('href')).toEqual(PREV_COMMIT_URL);
      });

      it('triggers the correct Vuex action on click', async () => {
        const link = getPrevCommitNavElement();

        link.trigger('click');
        await nextTick();
        expect(store.dispatch).toHaveBeenCalledWith('diffs/moveToNeighboringCommit', {
          direction: 'previous',
        });
      });

      it('renders a disabled button when there is no prev commit', () => {
        createWrapper({ commitArgs: { ...mrCommit, prev_commit_id: null } });

        const button = getPrevCommitNavElement();

        expect(button.element.hasAttribute('disabled')).toEqual(true);
      });
    });

    describe('next commit', () => {
      beforeAll(() => {
        setWindowLocation(`?commit_id=${mrCommit.id}`);
      });

      it('uses the correct href', () => {
        const link = getNextCommitNavElement();

        expect(link.element.getAttribute('href')).toEqual(NEXT_COMMIT_URL);
      });

      it('triggers the correct Vuex action on click', async () => {
        const link = getNextCommitNavElement();

        link.trigger('click');
        await nextTick();
        expect(store.dispatch).toHaveBeenCalledWith('diffs/moveToNeighboringCommit', {
          direction: 'next',
        });
      });

      it('renders a disabled button when there is no next commit', () => {
        createWrapper({ commitArgs: { ...mrCommit, next_commit_id: null } });

        const button = getNextCommitNavElement();

        expect(button.element.hasAttribute('disabled')).toEqual(true);
      });
    });
  });
});
