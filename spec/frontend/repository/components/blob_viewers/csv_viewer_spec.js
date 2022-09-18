import { shallowMount } from '@vue/test-utils';
import CsvViewer from '~/repository/components/blob_viewers/csv_viewer.vue';

describe('CSV Viewer', () => {
  let wrapper;

  const DEFAULT_BLOB_DATA = {
    rawPath: 'some/file.csv',
    name: 'file.csv',
  };

  const createComponent = () => {
    wrapper = shallowMount(CsvViewer, {
      propsData: { blob: DEFAULT_BLOB_DATA },
      stubs: ['CsvViewer'],
    });
  };

  const findCsvViewerComp = () => wrapper.find('[data-testid="csv"]');

  it('renders a Source Editor component', () => {
    createComponent();
    expect(findCsvViewerComp().exists()).toBe(true);
    expect(findCsvViewerComp().props('remoteFile')).toBe(true);
    expect(findCsvViewerComp().props('csv')).toBe(DEFAULT_BLOB_DATA.rawPath);
  });
});
