import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WidgetContentRow from '~/vue_merge_request_widget/components/widget/widget_content_row.vue';
import StatusIcon from '~/vue_merge_request_widget/components/widget/status_icon.vue';

describe('~/vue_merge_request_widget/components/widget/widget_content_row.vue', () => {
  let wrapper;

  const findStatusIcon = () => wrapper.findComponent(StatusIcon);

  const createComponent = ({ propsData, slots } = {}) => {
    wrapper = shallowMountExtended(WidgetContentRow, {
      propsData: {
        widgetName: 'MyWidget',
        level: 2,
        ...propsData,
      },
      slots,
    });
  };

  describe('body', () => {
    it('renders the status icon when provided', () => {
      createComponent({ propsData: { statusIconName: 'failed' } });
      expect(findStatusIcon().exists()).toBe(true);
    });

    it('does not render the status icon when it is not provided', () => {
      createComponent();
      expect(findStatusIcon().exists()).toBe(false);
    });

    it('renders slots properly', () => {
      createComponent({
        propsData: {
          statusIconName: 'success',
        },
        slots: {
          header: '<span>this is a header</span>',
          'header-actions': '<span>this is a header action</span>',
          body: '<span>this is a body</span>',
        },
      });

      expect(wrapper.findByText('this is a body').exists()).toBe(true);
      expect(wrapper.findByText('this is a header').exists()).toBe(true);
      expect(wrapper.findByText('this is a header action').exists()).toBe(true);
    });
  });

  describe('header', () => {
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
});
