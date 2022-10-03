import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WidgetContentHeader from '~/vue_merge_request_widget/components/widget/widget_content_header.vue';

describe('~/vue_merge_request_widget/components/widget/widget_content_header.vue', () => {
  let wrapper;

  const createComponent = ({ propsData } = {}) => {
    wrapper = shallowMountExtended(WidgetContentHeader, {
      propsData: {
        widgetName: 'MyWidget',
        ...propsData,
      },
    });
  };

  it('renders an array of header and subheader', () => {
    createComponent({ propsData: { header: ['this is a header', 'this is a subheader'] } });
    expect(wrapper.findByText('this is a header').exists()).toBe(true);
    expect(wrapper.findByText('this is a subheader').exists()).toBe(true);
  });

  it('renders a string', () => {
    createComponent({ propsData: { header: 'this is a header' } });
    expect(wrapper.findByText('this is a header').exists()).toBe(true);
  });

  it('escapes html injection properly', () => {
    createComponent({ propsData: { header: '<b role="header">this is a header</b>' } });
    expect(wrapper.findByText('<b role="header">this is a header</b>').exists()).toBe(true);
  });
});
