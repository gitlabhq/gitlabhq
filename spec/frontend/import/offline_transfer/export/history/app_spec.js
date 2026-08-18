import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import OfflineTransferExportHistoryApp from '~/import/offline_transfer/export/history/app.vue';

describe('OfflineTransferExportHistoryApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(OfflineTransferExportHistoryApp);
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders', () => {
    expect(wrapper.findComponent(OfflineTransferExportHistoryApp).exists()).toBe(true);
  });
});
