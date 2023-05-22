import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NothingToMerge from '~/vue_merge_request_widget/components/states/nothing_to_merge.vue';

describe('NothingToMerge', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(NothingToMerge, {
      stubs: {
        GlSprintf,
      },
    });
  };

  const findNothingToMergeTextBody = () => wrapper.findByTestId('nothing-to-merge-body');

  describe('With Blob link', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows the component with the correct text and highlights', () => {
      expect(wrapper.text()).toContain('Merge request contains no changes');
      expect(findNothingToMergeTextBody().text()).toContain(
        'Use merge requests to propose changes to your project and discuss them with your team. To make changes, use the Code dropdown list above, then test them with CI/CD before merging.',
      );
    });
  });
});
