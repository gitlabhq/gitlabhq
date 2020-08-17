import { shallowMount } from '@vue/test-utils';
import { GlFormInputGroup } from '@gitlab/ui';
import BlobEmbeddable from '~/blob/components/blob_embeddable.vue';

describe('Blob Embeddable', () => {
  let wrapper;
  const url = 'https://foo.bar';

  function createComponent() {
    wrapper = shallowMount(BlobEmbeddable, {
      propsData: {
        url,
      },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders gl-form-input-group component', () => {
    expect(wrapper.find(GlFormInputGroup).exists()).toBe(true);
  });

  it('makes up optionValues based on the url prop', () => {
    expect(wrapper.vm.optionValues).toEqual([
      { name: 'Embed', value: expect.stringContaining(`${url}.js`) },
      { name: 'Share', value: url },
    ]);
  });
});
