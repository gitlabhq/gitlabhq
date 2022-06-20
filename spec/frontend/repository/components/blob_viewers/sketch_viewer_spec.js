import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SketchViewer from '~/repository/components/blob_viewers/sketch_viewer.vue';
import SketchLoader from '~/blob/sketch';

jest.mock('~/blob/sketch');

describe('Sketch Viewer', () => {
  let wrapper;

  const DEFAULT_BLOB_DATA = {
    rawPath: 'some/file.sketch',
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(SketchViewer, {
      propsData: { blob: DEFAULT_BLOB_DATA },
    });
  };

  const findSketchWrapper = () => wrapper.findByTestId('sketch');

  beforeEach(() => createComponent());

  it('inits the sketch loader', () => {
    expect(SketchLoader).toHaveBeenCalledWith(wrapper.vm.$refs.viewer);
  });

  it('renders the sketch viewer', () => {
    expect(findSketchWrapper().exists()).toBe(true);
    expect(findSketchWrapper().attributes('data-endpoint')).toBe(DEFAULT_BLOB_DATA.rawPath);
  });
});
