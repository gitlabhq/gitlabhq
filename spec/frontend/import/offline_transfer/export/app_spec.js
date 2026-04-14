import { shallowMount } from '@vue/test-utils';
import OfflineTransferExportApp from '~/import/offline_transfer/export/app.vue';

describe('OfflineTransferExportApp', () => {
  let wrapper;

  const createComponent = ({ mountFn = shallowMount } = {}) => {
    wrapper = mountFn(OfflineTransferExportApp);
  };

  it('renders', () => {
    createComponent();
    expect(wrapper.findComponent(OfflineTransferExportApp).text()).toContain(
      'Export for offline transfer',
    );
  });
});
