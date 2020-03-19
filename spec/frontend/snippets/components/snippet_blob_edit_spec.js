import SnippetBlobEdit from '~/snippets/components/snippet_blob_edit.vue';
import BlobHeaderEdit from '~/blob/components/blob_edit_header.vue';
import BlobContentEdit from '~/blob/components/blob_edit_content.vue';
import { shallowMount } from '@vue/test-utils';

jest.mock('~/blob/utils', () => jest.fn());

describe('Snippet Blob Edit component', () => {
  let wrapper;
  const content = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.';
  const fileName = 'lorem.txt';

  function createComponent() {
    wrapper = shallowMount(SnippetBlobEdit, {
      propsData: {
        content,
        fileName,
      },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('rendering', () => {
    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders required components', () => {
      expect(wrapper.contains(BlobHeaderEdit)).toBe(true);
      expect(wrapper.contains(BlobContentEdit)).toBe(true);
    });
  });
});
