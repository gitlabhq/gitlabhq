import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import OfflineTransferApp from '~/import/offline_transfer/app.vue';

describe('OfflineTransferApp', () => {
  let wrapper;

  const createComponent = ({ mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(OfflineTransferApp);
  };

  it('renders', () => {
    createComponent();
    expect(wrapper.findByTestId('offline-transfer-subheading').text()).toBe(
      'Move groups and their contents to any GitLab instance, even with no network connection between this and the destination instance. With offline transfer you can export groups to an object storage you control, then import the files into the destination instance.',
    );
  });
});
