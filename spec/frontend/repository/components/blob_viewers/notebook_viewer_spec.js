import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NotebookViewer from '~/repository/components/blob_viewers/notebook_viewer.vue';
import notebookLoader from '~/blob/notebook';

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

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findNotebookWrapper = () => wrapper.findByTestId('notebook');

  beforeEach(() => createComponent());

  it('calls the notebook loader', () => {
    expect(notebookLoader).toHaveBeenCalledWith({
      el: wrapper.vm.$refs.viewer,
      relativeRawPath: ROOT_RELATIVE_PATH,
    });
  });

  it('renders a loading icon component', () => {
    expect(findLoadingIcon().props('size')).toBe('lg');
  });

  it('renders the notebook wrapper', () => {
    expect(findNotebookWrapper().exists()).toBe(true);
    expect(findNotebookWrapper().attributes('data-endpoint')).toBe(DEFAULT_BLOB_DATA.rawPath);
  });
});
