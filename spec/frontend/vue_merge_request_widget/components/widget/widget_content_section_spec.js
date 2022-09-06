import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WidgetContentSection from '~/vue_merge_request_widget/components/widget/widget_content_section.vue';
import StatusIcon from '~/vue_merge_request_widget/components/extensions/status_icon.vue';

describe('~/vue_merge_request_widget/components/widget/widget_content_section.vue', () => {
  let wrapper;

  const findStatusIcon = () => wrapper.findComponent(StatusIcon);

  const createComponent = ({ propsData, slots } = {}) => {
    wrapper = shallowMountExtended(WidgetContentSection, {
      propsData: {
        widgetName: 'MyWidget',
        ...propsData,
      },
      slots,
    });
  };

  it('does not render the status icon when it is not provided', () => {
    createComponent();
    expect(findStatusIcon().exists()).toBe(false);
  });

  it('renders the status icon when provided', () => {
    createComponent({ propsData: { statusIconName: 'failed' } });
    expect(findStatusIcon().exists()).toBe(true);
  });

  it('renders the default slot', () => {
    createComponent({
      slots: {
        default: 'Hello world',
      },
    });

    expect(wrapper.findByText('Hello world').exists()).toBe(true);
  });
});
