import { mount } from '@vue/test-utils';
import _ from 'lodash';
import { TEST_HOST } from 'helpers/test_constants';
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

  const findMRStatus = () => wrapper.findComponent(IdeStatusMR);

  const mountComponent = (state = {}) => {
    const store = createStore();
    store.replaceState({
      ...store.state,
      currentBranchId: 'main',
      currentProjectId: TEST_PROJECT_ID,
      projects: {
        ...store.state.projects,
        [TEST_PROJECT_ID]: _.clone(projectData),
      },
      ...state,
    });

    wrapper = mount(IdeStatusBar, { store });
  };

  describe('default', () => {
    it('triggers a setInterval', () => {
      mountComponent();

      expect(wrapper.vm.intervalId).not.toBe(null);
    });

    it('renders the statusbar', () => {
      mountComponent();

      expect(wrapper.classes()).toEqual(['ide-status-bar']);
    });

    describe('commitAgeUpdate', () => {
      beforeEach(() => {
        mountComponent();
        jest.spyOn(wrapper.vm, 'commitAgeUpdate').mockImplementation(() => {});
      });

      afterEach(() => {
        jest.clearAllTimers();
      });

      it('gets called every second', () => {
        expect(wrapper.vm.commitAgeUpdate).not.toHaveBeenCalled();

        jest.advanceTimersByTime(1000);

        expect(wrapper.vm.commitAgeUpdate.mock.calls).toHaveLength(1);

        jest.advanceTimersByTime(1000);

        expect(wrapper.vm.commitAgeUpdate.mock.calls).toHaveLength(2);
      });
    });

    describe('getCommitPath', () => {
      it('returns the path to the commit details', () => {
        mountComponent();

        expect(wrapper.vm.getCommitPath('abc123de')).toBe('/commit/abc123de');
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
        jest.spyOn(wrapper.vm, 'openRightPane').mockImplementation(() => {});

        wrapper.find('button').trigger('click');

        expect(wrapper.vm.openRightPane).toHaveBeenCalledWith(rightSidebarViews.pipelines);
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
            ..._.clone(projectData),
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
