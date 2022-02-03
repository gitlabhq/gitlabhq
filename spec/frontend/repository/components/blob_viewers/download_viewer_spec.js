import { GlLink, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import DownloadViewer from '~/repository/components/blob_viewers/download_viewer.vue';

describe('Text Viewer', () => {
  let wrapper;

  const DEFAULT_BLOB_DATA = {
    name: 'file_name.js',
    rawPath: '/some/file/path',
    rawSize: 2269674,
  };

  const createComponent = (blobData = {}) => {
    wrapper = shallowMount(DownloadViewer, {
      propsData: {
        blob: {
          ...DEFAULT_BLOB_DATA,
          ...blobData,
        },
      },
    });
  };

  it('renders download human readable file size text', () => {
    createComponent();

    const downloadText = `Download (${numberToHumanSize(DEFAULT_BLOB_DATA.rawSize)})`;
    expect(wrapper.text()).toBe(downloadText);
  });

  it('renders download text', () => {
    createComponent({
      rawSize: 0,
    });

    expect(wrapper.text()).toBe('Download');
  });

  it('renders download link', () => {
    createComponent();
    const { rawPath, name } = DEFAULT_BLOB_DATA;

    expect(wrapper.findComponent(GlLink).attributes()).toMatchObject({
      rel: 'nofollow',
      target: '_blank',
      href: rawPath,
      download: name,
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
