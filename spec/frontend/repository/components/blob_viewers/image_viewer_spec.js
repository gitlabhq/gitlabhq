import { shallowMount } from '@vue/test-utils';
import ImageViewer from '~/repository/components/blob_viewers/image_viewer.vue';

describe('Image Viewer', () => {
  let wrapper;

  const propsData = {
    url: 'some/image.png',
    alt: 'image.png',
  };

  const createComponent = () => {
    wrapper = shallowMount(ImageViewer, { propsData });
  };

  const findImage = () => wrapper.find('[data-testid="image"]');

  it('renders a Source Editor component', () => {
    createComponent();

    expect(findImage().exists()).toBe(true);
    expect(findImage().attributes('src')).toBe(propsData.url);
    expect(findImage().attributes('alt')).toBe(propsData.alt);
  });
});
