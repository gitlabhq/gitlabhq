import { nextTick } from 'vue';
import { GlAlert, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WidgetWrapper from '~/work_items/components/widget_wrapper.vue';

describe('WidgetWrapper component', () => {
  let wrapper;

  const createComponent = ({ error, widgetName } = {}) => {
    wrapper = shallowMountExtended(WidgetWrapper, { propsData: { error, widgetName } });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findToggleButton = () => wrapper.findComponent(GlButton);
  const findWidgetBody = () => wrapper.findByTestId('widget-body');
  const findWidgetWrapper = () => wrapper.findByTestId('widget-wrapper');

  it('is expanded by default', () => {
    createComponent();

    const toggleButton = findToggleButton();

    expect(toggleButton.props('icon')).toBe('chevron-lg-up');
    expect(toggleButton.attributes('aria-expanded')).toBe('true');
    expect(findWidgetWrapper().classes()).not.toContain('is-collapsed');
    expect(findWidgetBody().exists()).toBe(true);
  });

  it('collapses on click toggle button', async () => {
    createComponent();
    findToggleButton().vm.$emit('click');
    await nextTick();

    const toggleButton = findToggleButton();

    expect(toggleButton.props('icon')).toBe('chevron-lg-down');
    expect(toggleButton.attributes('aria-expanded')).toBe('false');
    expect(findWidgetWrapper().classes()).toContain('is-collapsed');
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

  describe('"aria-controls" attribute', () => {
    it('is set and identifies the correct element', () => {
      createComponent({ widgetName: 'test-widget-name' });

      expect(findWidgetWrapper().attributes('id')).toBe('test-widget-name');
      expect(findToggleButton().attributes('aria-controls')).toBe('test-widget-name');
    });
  });
});
