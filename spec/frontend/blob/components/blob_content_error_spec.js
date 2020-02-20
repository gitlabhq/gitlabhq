import { shallowMount } from '@vue/test-utils';
import BlobContentError from '~/blob/components/blob_content_error.vue';

describe('Blob Content Error component', () => {
  let wrapper;
  const viewerError = '<h1 id="error">Foo Error</h1>';

  function createComponent() {
    wrapper = shallowMount(BlobContentError, {
      propsData: {
        viewerError,
      },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the passed error without transformations', () => {
    expect(wrapper.html()).toContain(viewerError);
  });
});
