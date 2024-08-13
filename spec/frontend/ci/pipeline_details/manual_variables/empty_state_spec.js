import { shallowMount } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';
import EmptyState from '~/ci/pipeline_details/manual_variables/empty_state.vue';

describe('ManualVariablesEmptyState', () => {
  describe('when component is created', () => {
    let wrapper;

    const createComponent = () => {
      wrapper = shallowMount(EmptyState);
    };
    const findEmptyState = () => wrapper.findComponent(GlEmptyState);

    it('should render empty state with message', () => {
      createComponent();

      expect(findEmptyState().props()).toMatchObject({
        svgPath: EmptyState.EMPTY_VARIABLES_SVG,
        title: 'There are no manually-specified variables for this pipeline',
      });
    });
  });
});
