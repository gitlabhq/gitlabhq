import { shallowMount } from '@vue/test-utils';
import MissingBranchComponent from '~/vue_merge_request_widget/components/states/mr_widget_missing_branch.vue';

let wrapper;

function factory(sourceBranchRemoved, mergeRequestWidgetGraphql) {
  wrapper = shallowMount(MissingBranchComponent, {
    propsData: {
      mr: { sourceBranchRemoved },
    },
    provide: {
      glFeatures: { mergeRequestWidgetGraphql },
    },
  });

  if (mergeRequestWidgetGraphql) {
    wrapper.setData({ state: { sourceBranchExists: !sourceBranchRemoved } });
  }

  return wrapper.vm.$nextTick();
}

describe('MRWidgetMissingBranch', () => {
  afterEach(() => {
    wrapper.destroy();
  });

  [true, false].forEach(mergeRequestWidgetGraphql => {
    describe(`widget GraphQL feature flag is ${
      mergeRequestWidgetGraphql ? 'enabled' : 'disabled'
    }`, () => {
      it.each`
        sourceBranchRemoved | branchName
        ${true}             | ${'source'}
        ${false}            | ${'target'}
      `(
        'should set missing branch name as $branchName when sourceBranchRemoved is $sourceBranchRemoved',
        async ({ sourceBranchRemoved, branchName }) => {
          await factory(sourceBranchRemoved, mergeRequestWidgetGraphql);

          expect(wrapper.find('[data-testid="missingBranchName"]').text()).toContain(branchName);
        },
      );
    });
  });
});
