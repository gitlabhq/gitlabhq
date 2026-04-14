import { shallowMount } from '@vue/test-utils';
import OfflineTransferImportApp from '~/import/offline_transfer/import/app.vue';

describe('OfflineTransferImportApp', () => {
  let wrapper;

  const createComponent = ({ mountFn = shallowMount } = {}) => {
    wrapper = mountFn(OfflineTransferImportApp);
  };

  it('renders', () => {
    createComponent();
    expect(wrapper.findComponent(OfflineTransferImportApp).text()).toContain(
      'Import an offline transfer',
    );
  });
});
