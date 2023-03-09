import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import DiagramPerformanceWarning from '~/behaviors/components/diagram_performance_warning.vue';

describe('DiagramPerformanceWarning component', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);

  beforeEach(() => {
    wrapper = shallowMount(DiagramPerformanceWarning);
  });

  it('renders warning alert with button', () => {
    expect(findAlert().props()).toMatchObject({
      primaryButtonText: DiagramPerformanceWarning.i18n.buttonText,
      variant: 'warning',
    });
  });

  it('renders warning message', () => {
    expect(findAlert().text()).toBe(DiagramPerformanceWarning.i18n.bodyText);
  });

  it('emits event when closing alert', () => {
    findAlert().vm.$emit('dismiss');

    expect(wrapper.emitted('closeAlert')).toEqual([[]]);
  });

  it('emits event when accepting alert', () => {
    findAlert().vm.$emit('primaryAction');

    expect(wrapper.emitted('showImage')).toEqual([[]]);
  });
});
