import { GlEmptyState } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import OfflineTransferExportHistoryApp from '~/import/offline_transfer/export/history/app.vue';

describe('OfflineTransferExportHistoryApp', () => {
  let wrapper;

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  const createComponent = () => {
    wrapper = shallowMountExtended(OfflineTransferExportHistoryApp);
  };

  beforeEach(() => {
    createComponent();
  });

  describe('when there are no exports', () => {
    it('renders the empty state', () => {
      expect(findEmptyState().props('title')).toBe('No history is available yet');
      expect(findEmptyState().props('description')).toBe(
        'Groups exported through offline transfer appear here.',
      );
    });
  });
});
