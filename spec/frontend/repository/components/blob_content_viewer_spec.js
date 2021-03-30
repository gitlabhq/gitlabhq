import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import BlobContent from '~/blob/components/blob_content.vue';
import BlobHeader from '~/blob/components/blob_header.vue';
import BlobContentViewer from '~/repository/components/blob_content_viewer.vue';

let wrapper;
const mockData = {
  name: 'some_file.js',
  size: 123,
  rawBlob: 'raw content',
  type: 'text',
  fileType: 'text',
  tooLarge: false,
  path: 'some_file.js',
  editBlobPath: 'some_file.js/edit',
  ideEditPath: 'some_file.js/ide/edit',
  storedExternally: false,
  rawPath: 'some_file.js',
  externalStorageUrl: 'some_file.js',
  replacePath: 'some_file.js/replace',
  deletePath: 'some_file.js/delete',
  canLock: true,
  isLocked: false,
  lockLink: 'some_file.js/lock',
  canModifyBlob: true,
  forkPath: 'some_file.js/fork',
  simpleViewer: {},
  richViewer: {},
};

function factory(path, loading = false) {
  wrapper = shallowMount(BlobContentViewer, {
    propsData: {
      path,
    },
    mocks: {
      $apollo: {
        queries: {
          blobInfo: {
            loading,
          },
        },
      },
    },
  });

  wrapper.setData({ blobInfo: mockData });
}

describe('Blob content viewer component', () => {
  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);
  const findBlobHeader = () => wrapper.find(BlobHeader);
  const findBlobContent = () => wrapper.find(BlobContent);

  afterEach(() => {
    wrapper.destroy();
  });

  beforeEach(() => {
    factory('some_file.js');
  });

  it('renders a GlLoadingIcon component', () => {
    factory('some_file.js', true);

    expect(findLoadingIcon().exists()).toBe(true);
  });

  it('renders a BlobHeader component', () => {
    expect(findBlobHeader().exists()).toBe(true);
  });

  it('renders a BlobContent component', () => {
    expect(findBlobContent().exists()).toBe(true);

    expect(findBlobContent().props('loading')).toEqual(false);
    expect(findBlobContent().props('content')).toEqual('raw content');
    expect(findBlobContent().props('isRawContent')).toBe(true);
    expect(findBlobContent().props('activeViewer')).toEqual({
      fileType: 'text',
      tooLarge: false,
      type: 'text',
    });
  });
});
