import { shallowMount } from '@vue/test-utils';
import MissingBranchComponent from '~/vue_merge_request_widget/components/states/mr_widget_missing_branch.vue';

let wrapper;

function factory(sourceBranchRemoved) {
  wrapper = shallowMount(MissingBranchComponent, {
    propsData: {
      mr: { sourceBranchRemoved },
    },
    data() {
      return { state: { sourceBranchExists: !sourceBranchRemoved } };
    },
  });
}

describe('MRWidgetMissingBranch', () => {
  it.each`
    sourceBranchRemoved | branchName
    ${true}             | ${'source'}
    ${false}            | ${'target'}
  `(
    'should set missing branch name as $branchName when sourceBranchRemoved is $sourceBranchRemoved',
    ({ sourceBranchRemoved, branchName }) => {
      factory(sourceBranchRemoved);

      expect(wrapper.find('[data-testid="widget-content"]').text()).toContain(branchName);
    },
  );
});
