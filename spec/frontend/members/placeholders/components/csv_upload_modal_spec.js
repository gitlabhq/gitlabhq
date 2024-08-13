import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CsvUploadModal from '~/members/placeholders/components/csv_upload_modal.vue';

describe('CsvUploadModal', () => {
  let wrapper;

  const defaultInjectedAttributes = {
    reassignmentCsvPath: 'foo/bar',
  };

  const findDownloadLink = () => wrapper.findByTestId('csv-download-button');

  function createComponent() {
    return shallowMountExtended(CsvUploadModal, {
      propsData: {
        modalId: 'csv-upload-modal',
      },
      provide: {
        ...defaultInjectedAttributes,
      },
    });
  }

  beforeEach(() => {
    wrapper = createComponent();
  });

  it('has the CSV download button with the required attributes', () => {
    const downloadLink = findDownloadLink();

    expect(downloadLink.exists()).toBe(true);
    expect(downloadLink.attributes('href')).toBe(defaultInjectedAttributes.reassignmentCsvPath);
  });
});
