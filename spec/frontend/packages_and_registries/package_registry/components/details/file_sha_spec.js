import { shallowMount } from '@vue/test-utils';

import FileSha from '~/packages_and_registries/package_registry/components/details/file_sha.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import DetailsRow from '~/vue_shared/components/registry/details_row.vue';

describe('FileSha', () => {
  let wrapper;

  const defaultProps = { sha: 'foo', title: 'bar' };

  function createComponent() {
    wrapper = shallowMount(FileSha, {
      propsData: {
        ...defaultProps,
      },
      stubs: {
        ClipboardButton,
        DetailsRow,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders', () => {
    createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });
});
