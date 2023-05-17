import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import LfsViewer from '~/repository/components/blob_viewers/lfs_viewer.vue';

describe('LFS Viewer', () => {
  let wrapper;

  const DEFAULT_BLOB_DATA = {
    name: 'file_name.js',
    rawPath: '/some/file/path',
  };

  const createComponent = (blobData = {}) => {
    wrapper = shallowMount(LfsViewer, {
      propsData: { blob: { ...DEFAULT_BLOB_DATA, ...blobData } },
      stubs: { GlSprintf },
    });
  };

  const findLink = () => wrapper.findComponent(GlLink);

  beforeEach(() => createComponent());

  it('renders the correct text', () => {
    expect(wrapper.text()).toBe(
      'This content could not be displayed because it is stored in LFS. You can download it instead.',
    );
  });

  it('renders download link', () => {
    const { rawPath, name } = DEFAULT_BLOB_DATA;

    expect(findLink().attributes()).toMatchObject({
      target: '_blank',
      href: rawPath,
      download: name,
    });
  });

  it('renders the correct link href when stored externally', () => {
    const externalStorageUrl = 'https://cdn.test.com/project/some/file.js?token=1234';
    createComponent({ externalStorageUrl });

    expect(findLink().attributes('href')).toBe(externalStorageUrl);
  });
});
