import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import axios from '~/lib/utils/axios_utils';
import CompareApp from '~/merge_requests/components/compare_app.vue';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

let wrapper;
let mock;

function factory(provideData = {}) {
  wrapper = shallowMountExtended(CompareApp, {
    provide: {
      inputs: {
        project: {
          id: 'project',
          name: 'project',
        },
        branch: {
          id: 'branch',
          name: 'branch',
        },
      },
      branchCommitPath: '/commit',
      toggleClass: {
        project: 'project',
        branch: 'branch',
      },
      i18n: {
        projectHeaderText: 'Project',
        branchHeaderText: 'Branch',
      },
      ...provideData,
    },
  });
}

const findCommitBox = () => wrapper.findByTestId('commit-box');

describe('Merge requests compare app component', () => {
  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet('/commit').reply(HTTP_STATUS_OK, 'commit content');
  });

  afterEach(() => {
    mock.restore();
  });

  it('shows commit box when selected branch is empty', () => {
    factory({
      currentBranch: {
        text: '',
        value: '',
      },
    });

    const commitBox = findCommitBox();

    expect(commitBox.exists()).toBe(true);
    expect(commitBox.text()).toBe('Select a branch to compare');
  });

  it('emits select-branch on selected event', () => {
    factory({
      currentBranch: {
        text: '',
        value: '',
      },
    });

    wrapper.findByTestId('compare-dropdown').vm.$emit('selected', { value: 'main' });

    expect(wrapper.emitted('select-branch')).toEqual([['main']]);
  });

  describe('currentBranch watcher', () => {
    it('changes selected value', async () => {
      factory({
        currentBranch: {
          text: '',
          value: '',
        },
      });

      expect(findCommitBox().text()).toBe('Select a branch to compare');

      wrapper.setProps({ currentBranch: { text: 'main', value: 'main ' } });

      await waitForPromises();

      expect(findCommitBox().text()).toBe('commit content');
    });
  });
});
