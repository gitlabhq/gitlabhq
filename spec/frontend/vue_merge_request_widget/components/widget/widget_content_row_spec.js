import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WidgetContentRow from '~/vue_merge_request_widget/components/widget/widget_content_row.vue';
import WidgetContentBody from '~/vue_merge_request_widget/components/widget/widget_content_body.vue';

describe('~/vue_merge_request_widget/components/widget/widget_content_row.vue', () => {
  let wrapper;

  const findContentBody = () => wrapper.findComponent(WidgetContentBody);

  const createComponent = ({ propsData, slots } = {}) => {
    wrapper = shallowMountExtended(WidgetContentRow, {
      propsData: {
        widgetName: 'MyWidget',
        ...propsData,
      },
      slots,
    });
  };

  it('renders slots properly', () => {
    createComponent({
      propsData: {
        statusIconName: 'success',
        level: 2,
      },
      slots: {
        header: '<b>this is a header</b>',
        body: '<span>this is a body</span>',
      },
    });

    expect(wrapper.findByText('this is a header').exists()).toBe(true);
    expect(findContentBody().props()).toMatchObject({
      statusIconName: 'success',
      widgetName: 'MyWidget',
    });
  });
});
