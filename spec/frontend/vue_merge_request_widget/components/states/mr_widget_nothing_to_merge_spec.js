import { GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NothingToMerge from '~/vue_merge_request_widget/components/states/nothing_to_merge.vue';

describe('NothingToMerge', () => {
  let wrapper;
  const newBlobPath = '/foo';

  const defaultProps = {
    mr: {
      newBlobPath,
    },
  };

  const createComponent = (props = defaultProps) => {
    wrapper = shallowMountExtended(NothingToMerge, {
      propsData: {
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findCreateButton = () => wrapper.findByTestId('createFileButton');
  const findNothingToMergeTextBody = () => wrapper.findByTestId('nothing-to-merge-body');

  describe('With Blob link', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows the component with the correct text and highlights', () => {
      expect(wrapper.text()).toContain('This merge request contains no changes.');
      expect(findNothingToMergeTextBody().text()).toContain(
        'Use merge requests to propose changes to your project and discuss them with your team. To make changes, push a commit or edit this merge request to use a different branch.',
      );
    });

    it('shows the Create file button with the correct attributes', () => {
      const createButton = findCreateButton();

      expect(createButton.exists()).toBe(true);
      expect(createButton.attributes('href')).toBe(newBlobPath);
    });
  });

  describe('Without Blob link', () => {
    beforeEach(() => {
      createComponent({ mr: { newBlobPath: '' } });
    });

    it('does not show the Create file button', () => {
      expect(findCreateButton().exists()).toBe(false);
    });
  });
});
