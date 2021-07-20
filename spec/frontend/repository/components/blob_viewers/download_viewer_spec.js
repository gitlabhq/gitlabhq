import { GlLink, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import DownloadViewer from '~/repository/components/blob_viewers/download_viewer.vue';

describe('Text Viewer', () => {
  let wrapper;

  const DEFAULT_PROPS = {
    fileName: 'file_name.js',
    filePath: '/some/file/path',
    fileSize: 2269674,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(DownloadViewer, {
      propsData: {
        ...DEFAULT_PROPS,
        ...props,
      },
    });
  };

  it('renders component', () => {
    createComponent();

    const { fileName, filePath, fileSize } = DEFAULT_PROPS;
    expect(wrapper.props()).toMatchObject({
      fileName,
      filePath,
      fileSize,
    });
  });

  it('renders download human readable file size text', () => {
    createComponent();

    const downloadText = `Download (${numberToHumanSize(DEFAULT_PROPS.fileSize)})`;
    expect(wrapper.text()).toBe(downloadText);
  });

  it('renders download text', () => {
    createComponent({
      fileSize: 0,
    });

    expect(wrapper.text()).toBe('Download');
  });

  it('renders download link', () => {
    createComponent();
    const { filePath, fileName } = DEFAULT_PROPS;

    expect(wrapper.findComponent(GlLink).attributes()).toMatchObject({
      rel: 'nofollow',
      target: '_blank',
      href: filePath,
      download: fileName,
    });
  });

  it('renders download icon', () => {
    createComponent();

    expect(wrapper.findComponent(GlIcon).props()).toMatchObject({
      name: 'download',
      size: 16,
    });
  });
});
