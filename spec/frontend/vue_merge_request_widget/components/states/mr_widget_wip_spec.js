import { mount } from '@vue/test-utils';
import WorkInProgress from '~/vue_merge_request_widget/components/states/work_in_progress.vue';

let wrapper;

const createComponent = (updateMergeRequest = true) => {
  wrapper = mount(WorkInProgress, {
    propsData: {
      mr: {},
    },
    data() {
      return {
        userPermissions: {
          updateMergeRequest,
        },
      };
    },
  });
};

describe('Merge request widget draft state component', () => {
  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    it('should have correct elements', () => {
      createComponent(true);

      expect(wrapper.text()).toContain(
        "Merge blocked: merge request must be marked as ready. It's still marked as draft.",
      );
      expect(wrapper.find('[data-testid="removeWipButton"]').text()).toContain('Mark as ready');
    });

    it('should not show removeWIP button is user cannot update MR', () => {
      createComponent(false);

      expect(wrapper.find('[data-testid="removeWipButton"]').exists()).toBe(false);
    });
  });
});
