import { shallowMount } from '@vue/test-utils';
import { GlTruncate } from '@gitlab/ui';
import FileRowHeader from '~/vue_shared/components/file_row_header.vue';

describe('File row header component', () => {
  let wrapper;

  function createComponent(path) {
    wrapper = shallowMount(FileRowHeader, {
      propsData: {
        path,
      },
    });
  }

  it('renders file path', () => {
    const path = 'app/assets';
    createComponent(path);

    const truncate = wrapper.findComponent(GlTruncate);
    expect(truncate.exists()).toBe(true);
    expect(truncate.props('text')).toBe(path);
  });
});
