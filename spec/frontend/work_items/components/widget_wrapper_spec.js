import { nextTick } from 'vue';
import { GlAlert, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WidgetWrapper from '~/work_items/components/widget_wrapper.vue';

describe('WidgetWrapper component', () => {
  let wrapper;

  const createComponent = ({ error } = {}) => {
    wrapper = shallowMountExtended(WidgetWrapper, { propsData: { error } });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findToggleButton = () => wrapper.findComponent(GlButton);
  const findWidgetBody = () => wrapper.findByTestId('widget-body');

  it('is expanded by default', () => {
    createComponent();

    expect(findToggleButton().props('icon')).toBe('chevron-lg-up');
    expect(findWidgetBody().exists()).toBe(true);
  });

  it('collapses on click toggle button', async () => {
    createComponent();
    findToggleButton().vm.$emit('click');
    await nextTick();

    expect(findToggleButton().props('icon')).toBe('chevron-lg-down');
    expect(findWidgetBody().exists()).toBe(false);
  });

  it('shows an alert when list loading fails', () => {
    const error = 'Some error';
    createComponent({ error });

    expect(findAlert().text()).toBe(error);
  });

  it('emits event when dismissing the alert', () => {
    createComponent({ error: 'error' });
    findAlert().vm.$emit('dismiss');

    expect(wrapper.emitted('dismissAlert')).toEqual([[]]);
  });
});
