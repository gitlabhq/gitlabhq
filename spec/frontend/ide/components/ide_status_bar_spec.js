import { clone } from 'lodash';
import { TEST_HOST } from 'helpers/test_constants';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import IdeStatusBar from '~/ide/components/ide_status_bar.vue';
import IdeStatusMR from '~/ide/components/ide_status_mr.vue';
import { rightSidebarViews } from '~/ide/constants';
import { createStore } from '~/ide/stores';
import { projectData } from '../mock_data';

const TEST_PROJECT_ID = 'abcproject';
const TEST_MERGE_REQUEST_ID = '9001';
const TEST_MERGE_REQUEST_URL = `${TEST_HOST}merge-requests/${TEST_MERGE_REQUEST_ID}`;

jest.mock('~/lib/utils/poll');

describe('IdeStatusBar component', () => {
  let wrapper;
  const dummyIntervalId = 1337;
  let dispatchMock;

  const findMRStatus = () => wrapper.findComponent(IdeStatusMR);

  const mountComponent = (state = {}) => {
    const store = createStore();
    store.replaceState({
      ...store.state,
      currentBranchId: 'main',
      currentProjectId: TEST_PROJECT_ID,
      projects: {
        ...store.state.projects,
        [TEST_PROJECT_ID]: clone(projectData),
      },
      ...state,
    });

    wrapper = mountExtended(IdeStatusBar, { store });
    dispatchMock = jest.spyOn(store, 'dispatch');
  };

  beforeEach(() => {
    jest.spyOn(window, 'setInterval').mockReturnValue(dummyIntervalId);
  });

  const findCommitShaLink = () => wrapper.findByTestId('commit-sha-content');

  describe('default', () => {
    it('triggers a setInterval', () => {
      mountComponent();

      expect(window.setInterval).toHaveBeenCalledTimes(1);
    });

    it('renders the statusbar', () => {
      mountComponent();

      expect(wrapper.classes()).toEqual(['ide-status-bar']);
    });

    describe('getCommitPath', () => {
      it('returns the path to the commit details', () => {
        mountComponent();
        expect(findCommitShaLink().attributes('href')).toBe('/commit/abc123de');
      });
    });

    describe('pipeline status', () => {
      it('opens right sidebar on clicking icon', () => {
        const pipelines = {
          latestPipeline: {
            details: {
              status: {
                text: 'success',
                details_path: 'test',
                icon: 'status_success',
              },
            },
            commit: {
              author_gravatar_url: 'www',
            },
          },
        };
        mountComponent({ pipelines });

        wrapper.find('button').trigger('click');

        expect(dispatchMock).toHaveBeenCalledWith('rightPane/open', rightSidebarViews.pipelines);
      });
    });

    it('does not show merge request status', () => {
      mountComponent();

      expect(findMRStatus().exists()).toBe(false);
    });
  });

  describe('with merge request in store', () => {
    beforeEach(() => {
      const state = {
        currentMergeRequestId: TEST_MERGE_REQUEST_ID,
        projects: {
          [TEST_PROJECT_ID]: {
            ...clone(projectData),
            mergeRequests: {
              [TEST_MERGE_REQUEST_ID]: {
                web_url: TEST_MERGE_REQUEST_URL,
                references: {
                  short: `!${TEST_MERGE_REQUEST_ID}`,
                },
              },
            },
          },
        },
      };
      mountComponent(state);
    });

    it('shows merge request status', () => {
      expect(findMRStatus().text()).toBe(`Merge request !${TEST_MERGE_REQUEST_ID}`);
      expect(findMRStatus().find('a').attributes('href')).toBe(TEST_MERGE_REQUEST_URL);
    });
  });
});
