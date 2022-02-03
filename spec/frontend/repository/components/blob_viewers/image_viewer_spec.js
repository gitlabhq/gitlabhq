import { shallowMount } from '@vue/test-utils';
import ImageViewer from '~/repository/components/blob_viewers/image_viewer.vue';

describe('Image Viewer', () => {
  let wrapper;

  const DEFAULT_BLOB_DATA = {
    rawPath: 'some/image.png',
    name: 'image.png',
  };

  const createComponent = () => {
    wrapper = shallowMount(ImageViewer, { propsData: { blob: DEFAULT_BLOB_DATA } });
  };

  const findImage = () => wrapper.find('[data-testid="image"]');

  it('renders a Source Editor component', () => {
    createComponent();

    expect(findImage().exists()).toBe(true);
    expect(findImage().attributes('src')).toBe(DEFAULT_BLOB_DATA.rawPath);
    expect(findImage().attributes('alt')).toBe(DEFAULT_BLOB_DATA.name);
  });
});
