import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import OfflineTransferApp from '~/import/offline_transfer/app.vue';

describe('OfflineTransferApp', () => {
  let wrapper;

  const EXPORT_PATH = '/import/offline/export';
  const IMPORT_PATH = '/import/offline/import';

  const createComponent = ({ glFeatures = {} } = {}) => {
    wrapper = shallowMountExtended(OfflineTransferApp, {
      propsData: {
        exportPath: EXPORT_PATH,
        importPath: IMPORT_PATH,
      },
      provide: {
        glFeatures: {
          offlineTransferExports: true,
          offlineTransferImports: true,
          ...glFeatures,
        },
      },
    });
  };

  const findExportButton = () => wrapper.findByTestId('export-button');
  const findImportButton = () => wrapper.findByTestId('import-button');

  it('renders', () => {
    createComponent();
    expect(wrapper.findByTestId('offline-transfer-subheading').text()).toBe(
      'Migrate groups and projects between GitLab instances that have no network connection between them. Export top-level groups that you own to an object storage you control, then import them into the destination GitLab instance.',
    );
  });

  it.each([
    ['exports and imports', true, true],
    ['only exports', true, false],
    ['only imports', false, true],
  ])('when %s are enabled, renders the expected cards', (_, exportsEnabled, importsEnabled) => {
    createComponent({
      glFeatures: {
        offlineTransferExports: exportsEnabled,
        offlineTransferImports: importsEnabled,
      },
    });

    expect(findExportButton().exists()).toBe(exportsEnabled);
    expect(findImportButton().exists()).toBe(importsEnabled);

    if (exportsEnabled) {
      expect(findExportButton().attributes('href')).toBe(EXPORT_PATH);
    }

    if (importsEnabled) {
      expect(findImportButton().attributes('href')).toBe(IMPORT_PATH);
    }
  });
});
