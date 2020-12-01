import { shallowMount } from '@vue/test-utils';
import MergeHelpComponent from '~/vue_merge_request_widget/components/mr_widget_merge_help.vue';

describe('MRWidgetMergeHelp', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(MergeHelpComponent, {
      propsData: {
        missingBranch: 'this-is-not-the-branch-you-are-looking-for',
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('with missing branch', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders missing branch information', () => {
      expect(wrapper.find('.mr-widget-help').text()).toContain(
        'If the this-is-not-the-branch-you-are-looking-for branch exists in your local repository',
      );
    });
  });

  describe('without missing branch', () => {
    beforeEach(() => {
      createComponent({
        props: { missingBranch: '' },
      });
    });

    it('renders information about how to merge manually', () => {
      expect(wrapper.find('.mr-widget-help').text()).toContain(
        'You can merge this merge request manually',
      );
    });
  });
});
