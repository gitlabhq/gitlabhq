import { GlDisclosureDropdown, GlDisclosureDropdownGroup } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DownloadDropdown from '~/vue_shared/components/download_dropdown/download_dropdown.vue';

describe('Download Dropdown', () => {
  let wrapper;
  const httpUrl = 'http://foo.bar';
  const createDownloadItem = (text) => ({
    extraAttrs: { download: '', rel: 'nofollow' },
    text,
    href: `${httpUrl}/archive.${text}`,
  });
  const downloadLinks = [
    { text: 'zip', path: `${httpUrl}/archive.zip` },
    { text: 'tar.gz', path: `${httpUrl}/archive.tar.gz` },
    { text: 'tar.bz2', path: `${httpUrl}/archive.tar.bz2` },
    { text: 'tar', path: `${httpUrl}/archive.tar` },
  ];
  const sourceCodeGroupData = {
    name: 'Download source code',
    items: ['zip', 'tar.gz', 'tar.bz2', 'tar'].map(createDownloadItem),
  };

  const artifactsGroupData = {
    name: 'Download artifacts',
    items: ['zip', 'tar.gz', 'tar.bz2', 'tar'].map(createDownloadItem),
  };
  const defaultPropsData = {
    downloadLinks,
    downloadArtifacts: [],
    cssClass: '',
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findSourceCodeGroup = () => wrapper.findByTestId('source-code-group');
  const findArtifactsGroup = () => wrapper.findByTestId('artifacts-group');

  const createComponent = (propsData = defaultPropsData) => {
    wrapper = shallowMountExtended(DownloadDropdown, {
      propsData,
      stubs: {
        GlDisclosureDropdown,
        GlDisclosureDropdownGroup,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('Properties', () => {
    it('renders a GlDisclosureDropdown dropdown with correct props', () => {
      expect(findDropdown().props()).toMatchObject({
        toggleText: 'Download',
        placement: 'bottom-end',
        icon: 'download',
        autoClose: false,
      });
    });

    it('passes the cssClass prop to the Dropdown', () => {
      createComponent({ ...defaultPropsData, cssClass: 'test-class' });

      expect(findDropdown().vm.$el.classList).toContain('test-class');
    });
  });

  describe('Rendering', () => {
    it('does not render a border if there are no download links', () => {
      createComponent({ downloadLinks: [], downloadArtifacts: downloadLinks });

      expect(findArtifactsGroup().props('bordered')).toBe(false);
    });

    it('renders a border if there are download links', () => {
      createComponent({ downloadLinks, downloadArtifacts: downloadLinks });

      expect(findArtifactsGroup().props('bordered')).toBe(true);
    });
  });

  describe('Download links', () => {
    it('does not render download links if not set', () => {
      createComponent({ downloadLinks: [], downloadArtifacts: [] });

      expect(findSourceCodeGroup().exists()).toBe(false);
    });

    it('renders download links if set', () => {
      expect(findSourceCodeGroup().exists()).toBe(true);
    });

    it('renders with correct items', () => {
      expect(findSourceCodeGroup().props('group')).toEqual(sourceCodeGroupData);
    });
  });

  describe('Artifacts', () => {
    it('does not render download links if not set', () => {
      expect(findArtifactsGroup().exists()).toBe(false);
    });

    it('renders download links if set', () => {
      createComponent({ downloadLinks: [], downloadArtifacts: downloadLinks });

      expect(findArtifactsGroup().exists()).toBe(true);
    });

    it('renders with correct items', () => {
      createComponent({ downloadLinks: [], downloadArtifacts: downloadLinks });

      expect(findArtifactsGroup().props('group')).toEqual(artifactsGroupData);
    });
  });
});
