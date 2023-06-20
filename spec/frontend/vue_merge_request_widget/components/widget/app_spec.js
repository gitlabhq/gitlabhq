import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import App from '~/vue_merge_request_widget/components/widget/app.vue';

describe('MR Widget App', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(App, {
      propsData: {
        mr: {},
      },
    });
  };

  it('renders widget container', () => {
    createComponent();
    expect(wrapper.findByTestId('mr-widget-app').exists()).toBe(true);
  });
});
