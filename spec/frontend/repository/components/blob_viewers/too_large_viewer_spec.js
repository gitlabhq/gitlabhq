import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import TooLargeViewer from '~/repository/components/blob_viewers/too_large_viewer.vue';

describe('Too Large Viewer', () => {
  let wrapper;

  const DEFAULT_BLOB_DATA = {
    name: 'large_file.pdf',
    rawPath: '/path/to/file',
    richViewer: {
      tooLarge: true,
    },
  };

  const DEFAULT_LINK_ATTRIBUTES = {
    rel: 'nofollow',
    target: '_blank',
    href: DEFAULT_BLOB_DATA.rawPath,
  };

  const createComponent = (blobData = {}) => {
    wrapper = shallowMount(TooLargeViewer, {
      propsData: {
        blob: {
          ...DEFAULT_BLOB_DATA,
          ...blobData,
        },
      },
      stubs: { GlSprintf },
    });
  };

  const findLinks = () => wrapper.findAllComponents(GlLink);

  describe('when file is too large', () => {
    beforeEach(() => createComponent({ richViewer: { renderError: 'collapsed' } }));

    it('renders two links for raw view and download', () => {
      const links = findLinks();

      expect(links).toHaveLength(2);

      expect(links.at(0).attributes()).toMatchObject(DEFAULT_LINK_ATTRIBUTES);

      expect(links.at(1).attributes()).toMatchObject({
        ...DEFAULT_LINK_ATTRIBUTES,
        download: DEFAULT_BLOB_DATA.name,
      });
    });

    it('renders correct description text', () => {
      expect(wrapper.text()).toContain('You can either view the raw file or download it.');
    });
  });

  describe('when using external storage', () => {
    const externalStorageUrl = 'https://cdn.example.com/file.pdf';
    beforeEach(() => createComponent({ externalStorageUrl, richViewer: { tooLarge: true } }));

    it('uses external storage URL for download link', () => {
      expect(findLinks().at(0).attributes()).toMatchObject({
        ...DEFAULT_LINK_ATTRIBUTES,
        href: externalStorageUrl,
      });
    });
  });
});
