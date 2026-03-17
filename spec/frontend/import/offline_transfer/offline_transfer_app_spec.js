import { shallowMount } from '@vue/test-utils';
import OfflineTransferApp from '~/import/offline_transfer/components/app.vue';

describe('OfflineTransferApp', () => {
  let wrapper;

  const createComponent = ({ mountFn = shallowMount } = {}) => {
    wrapper = mountFn(OfflineTransferApp);
  };

  it('renders', () => {
    createComponent();
    expect(wrapper.findComponent(OfflineTransferApp).exists()).toBe(true);
  });
});
