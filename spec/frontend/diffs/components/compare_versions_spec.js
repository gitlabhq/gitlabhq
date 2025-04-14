import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import getDiffWithCommit from 'test_fixtures/merge_request_diffs/with_commit.json';
import setWindowLocation from 'helpers/set_window_location_helper';
import { TEST_HOST } from 'helpers/test_constants';
import { trimText } from 'helpers/text_helper';
import CompareVersionsComponent from '~/diffs/components/compare_versions.vue';
import FileBrowserToggle from '~/diffs/components/file_browser_toggle.vue';
import { useFileBrowser } from '~/diffs/stores/file_browser';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import diffsMockData from '../mock_data/merge_request_diffs';

const NEXT_COMMIT_URL = `${TEST_HOST}/?commit_id=next`;
const PREV_COMMIT_URL = `${TEST_HOST}/?commit_id=prev`;

beforeEach(() => {
  setWindowLocation(TEST_HOST);
});

Vue.use(PiniaVuePlugin);

describe('CompareVersions', () => {
  let wrapper;
  let pinia;
  const targetBranchName = 'tmp-wine-dev';
  const { commit } = getDiffWithCommit;

  const createWrapper = ({ props = {}, commitArgs = {}, createCommit = true } = {}) => {
    if (createCommit) {
      useLegacyDiffs().commit = { ...useLegacyDiffs().commit, ...commitArgs };
    }
    // force Vue 2 mode by eager store creation
    useFileBrowser();
    wrapper = mount(CompareVersionsComponent, {
      propsData: {
        toggleFileTreeVisible: true,
        ...props,
      },
      pinia,
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
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });

    const mergeRequestDiff = diffsMockData[0];

    useLegacyDiffs().addedLines = 10;
    useLegacyDiffs().removedLines = 20;
    useLegacyDiffs().diffFiles.push('test');
    useLegacyDiffs().targetBranchName = targetBranchName;
    useLegacyDiffs().mergeRequestDiff = mergeRequestDiff;
    useLegacyDiffs().mergeRequestDiffs = diffsMockData;
  });

  describe('template', () => {
    beforeEach(() => {
      createWrapper({ createCommit: false });
    });

    it('should render file browser toggle', () => {
      expect(wrapper.findComponent(FileBrowserToggle).exists()).toBe(true);
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

  describe('commit', () => {
    beforeEach(() => {
      useLegacyDiffs().commit = commit;
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
      useLegacyDiffs().mergeRequestDiffs = [];
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
        expect(useLegacyDiffs().moveToNeighboringCommit).toHaveBeenCalledWith({
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
        expect(useLegacyDiffs().moveToNeighboringCommit).toHaveBeenCalledWith({
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
