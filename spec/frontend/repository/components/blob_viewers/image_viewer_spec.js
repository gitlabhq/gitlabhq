import { shallowMount } from '@vue/test-utils';
import ImageViewer from '~/repository/components/blob_viewers/image_viewer.vue';

describe('Image Viewer', () => {
  let wrapper;

  const DEFAULT_BLOB_DATA = {
    rawPath: 'some/image.png',
    name: 'image.png',
    externalStorageUrl: '',
  };

  const createComponent = (blobData = DEFAULT_BLOB_DATA) => {
    wrapper = shallowMount(ImageViewer, { propsData: { blob: blobData } });
  };

  const findImage = () => wrapper.find('[data-testid="image"]');

  describe('When blob has externalStorageUrl', () => {
    const externalStorageUrl = 'http://img.server.com/lfs-object/21/45/foo_bar';

    it('renders a Source Editor component with externalStorageUrl', () => {
      const blobData = { ...DEFAULT_BLOB_DATA, externalStorageUrl };
      createComponent(blobData);

      expect(findImage().exists()).toBe(true);
      expect(findImage().element.src).toBe(externalStorageUrl);
      expect(findImage().attributes('alt')).toBe(DEFAULT_BLOB_DATA.name);
    });
  });

  describe('When blob does not have an externalStorageUrl', () => {
    it('renders a Source Editor component with rawPath', () => {
      createComponent(DEFAULT_BLOB_DATA);

      expect(findImage().exists()).toBe(true);
      expect(findImage().element.src).toBe(DEFAULT_BLOB_DATA.rawPath);
      expect(findImage().attributes('alt')).toBe(DEFAULT_BLOB_DATA.name);
    });
  });
});
