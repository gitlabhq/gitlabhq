import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NotebookViewer from '~/repository/components/blob_viewers/notebook_viewer.vue';
import Notebook from '~/blob/notebook/notebook_viewer.vue';

jest.mock('~/blob/notebook');

describe('Notebook Viewer', () => {
  let wrapper;

  const ROOT_RELATIVE_PATH = '/some/notebook/';
  const DEFAULT_BLOB_DATA = { rawPath: `${ROOT_RELATIVE_PATH}file.ipynb` };

  const createComponent = () => {
    wrapper = shallowMountExtended(NotebookViewer, {
      propsData: { blob: DEFAULT_BLOB_DATA },
    });
  };

  const findNotebook = () => wrapper.findComponent(Notebook);

  beforeEach(() => createComponent());

  it('renders a Notebook component', () => {
    expect(findNotebook().props('endpoint')).toBe(DEFAULT_BLOB_DATA.rawPath);
  });
});
