import { shallowMount } from '@vue/test-utils';
import BlobContentViewer from '~/repository/components/blob_content_viewer.vue';
import BlobPage from '~/repository/pages/blob.vue';

jest.mock('~/repository/utils/dom');

describe('Repository blob page component', () => {
  let wrapper;

  const findBlobContentViewer = () => wrapper.find(BlobContentViewer);
  const path = 'file.js';

  beforeEach(() => {
    wrapper = shallowMount(BlobPage, {
      propsData: { path, projectPath: 'some/path' },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('has a Blob Content Viewer component', () => {
    expect(findBlobContentViewer().exists()).toBe(true);
    expect(findBlobContentViewer().props('path')).toBe(path);
  });
});
