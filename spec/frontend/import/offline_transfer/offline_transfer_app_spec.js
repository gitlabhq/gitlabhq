import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import OfflineTransferApp from '~/import/offline_transfer/app.vue';

describe('OfflineTransferApp', () => {
  let wrapper;

  const createComponent = ({ mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(OfflineTransferApp);
  };

  it('renders', () => {
    createComponent();
    expect(wrapper.findComponent(OfflineTransferApp).exists()).toBe(true);
  });
});
