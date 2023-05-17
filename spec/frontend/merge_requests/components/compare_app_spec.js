import { shallowMount } from '@vue/test-utils';
import CompareApp from '~/merge_requests/components/compare_app.vue';

let wrapper;

function factory(provideData = {}) {
  wrapper = shallowMount(CompareApp, {
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

describe('Merge requests compare app component', () => {
  it('shows commit box when selected branch is empty', () => {
    factory({
      currentBranch: {
        text: '',
        value: '',
      },
    });

    const commitBox = wrapper.find('[data-testid="commit-box"]');

    expect(commitBox.exists()).toBe(true);
    expect(commitBox.text()).toBe('Select a branch to compare');
  });
});
