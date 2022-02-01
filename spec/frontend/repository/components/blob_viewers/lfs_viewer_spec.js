import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import LfsViewer from '~/repository/components/blob_viewers/lfs_viewer.vue';

describe('LFS Viewer', () => {
  let wrapper;

  const DEFAULT_PROPS = {
    fileName: 'file_name.js',
    filePath: '/some/file/path',
  };

  const createComponent = () => {
    wrapper = shallowMount(LfsViewer, {
      propsData: { ...DEFAULT_PROPS },
      stubs: { GlSprintf },
    });
  };

  const findLink = () => wrapper.findComponent(GlLink);

  beforeEach(() => createComponent());

  afterEach(() => wrapper.destroy());

  it('renders the correct text', () => {
    expect(wrapper.text()).toBe(
      'This content could not be displayed because it is stored in LFS. You can download it instead.',
    );
  });

  it('renders download link', () => {
    const { filePath, fileName } = DEFAULT_PROPS;

    expect(findLink().attributes()).toMatchObject({
      target: '_blank',
      href: filePath,
      download: fileName,
    });
  });
});
