import { GlButton, GlDisclosureDropdown } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RunPipelineButton from '~/ci/common/run_pipeline_button.vue';

describe('RunPipelineButton', () => {
  let wrapper;

  const defaultProps = {
    mergeRequestId: 123,
  };

  const defaultProvide = {
    newPipelinePath: '/project/-/pipelines/new',
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(RunPipelineButton, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        ...defaultProvide,
      },
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);
  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);

  describe('run pipeline button', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the button', () => {
      expect(findButton().text()).toBe('Run pipeline');
    });

    it('emits run-pipeline when clicked', () => {
      findButton().vm.$emit('click');

      expect(wrapper.emitted('run-pipeline')).toHaveLength(1);
    });

    it('shows loading state when isLoading is true', () => {
      createComponent({ props: { isLoading: true } });

      expect(findButton().props('loading')).toBe(true);
    });
  });

  describe('dropdown', () => {
    it('renders the dropdown with correct URL', () => {
      createComponent();
      const items = findDropdown().props('items');

      expect(items[0].href).toBe('/project/-/pipelines/new?merge_request_iid=123');
    });

    it('does not render the dropdown when mergeRequestId is not provided', () => {
      createComponent({
        props: { mergeRequestId: null },
      });

      expect(findDropdown().exists()).toBe(false);
    });
  });
});
