import { GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';
import BlobOverflowMenu from '~/repository/components/header_area/blob_overflow_menu.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

const Blob = {
  binary: false,
  name: 'dummy.md',
  path: 'foo/bar/dummy.md',
  rawPath: 'https://testing.com/flightjs/flight/snippets/51/raw',
  size: 75,
  simpleViewer: {
    collapsed: false,
    loadingPartialName: 'loading',
    renderError: null,
    tooLarge: false,
    type: 'simple',
    fileType: 'text',
  },
  richViewer: {
    collapsed: false,
    loadingPartialName: 'loading',
    renderError: null,
    tooLarge: false,
    type: 'rich',
    fileType: 'markdown',
  },
  ideEditPath: 'ide/edit',
  editBlobPath: 'edit/blob',
  gitpodBlobUrl: 'gitpod/blob/url',
  pipelineEditorPath: 'pipeline/editor/path',
};

const mockEnvironmentName = 'my.testing.environment';
const mockEnvironmentPath = 'https://my.testing.environment';

describe('Blob Overflow Menu', () => {
  let wrapper;

  const blobHash = 'foo-bar';

  function createComponent(propsData = {}, provided = {}) {
    wrapper = shallowMountExtended(BlobOverflowMenu, {
      provide: {
        blobHash,
        ...provided,
      },
      propsData: {
        rawPath: Blob.rawPath,
        ...propsData,
      },
      stub: {
        GlDisclosureDropdown,
        GlDisclosureDropdownItem,
      },
    });
  }

  const findDefaultBlobActions = () => wrapper.findByTestId('default-actions-container');
  const findDropdownItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findDropdownItemWithText = (text) =>
    findDropdownItems().wrappers.find((x) => {
      return x.props('item').text === text;
    });
  const findCopyFileContentItem = () => findDropdownItems().at(0);
  const findViewRawItem = () => findDropdownItems().at(1);
  const findDownloadItem = () => findDropdownItems().at(2);
  const findEnvironmentItem = () => findDropdownItems().at(3);

  beforeEach(() => {
    createComponent();
  });

  describe('Default blob actions', () => {
    it('renders component', () => {
      expect(findDefaultBlobActions().exists()).toBe(true);
    });

    describe('Copy file contents', () => {
      it('renders "Copy file contents" button as enabled if the viewer is Simple', () => {
        expect(findCopyFileContentItem().props('item')).toMatchObject({
          extraAttrs: { disabled: false },
        });
      });

      it('renders "Copy file contents" button as disabled if the viewer is Rich', () => {
        createComponent({
          activeViewer: 'rich',
        });

        expect(findCopyFileContentItem().props('item')).toMatchObject({
          extraAttrs: { disabled: true },
        });
      });

      it('does not render the copy button if a rendering error is set', () => {
        createComponent({
          hasRenderError: true,
        });

        expect(findDropdownItemWithText('Copy file contents')).toBeUndefined();
      });
    });

    describe('Open raw', () => {
      it('renders with correct props', () => {
        expect(findViewRawItem().props('item')).toMatchObject({
          href: Blob.rawPath,
        });
      });
    });

    describe('Download', () => {
      it('renders with correct props', () => {
        expect(findDownloadItem().props('item')).toMatchObject({
          href: `${Blob.rawPath}?inline=false`,
        });
      });
    });

    it('does not render the copy and view raw button if isBinary is set to true', () => {
      createComponent({ isBinary: true });

      expect(findDropdownItemWithText('Copy file contents')).toBeUndefined();
      expect(findDropdownItemWithText('Open raw')).toBeUndefined();
    });

    it('does not render the download button if canDownloadCode is set to false', () => {
      createComponent({}, { canDownloadCode: false });

      expect(findDropdownItemWithText('Download')).toBeUndefined();
    });

    describe('View on environment', () => {
      describe.each`
        environmentName        | environmentPath        | isVisible
        ${null}                | ${null}                | ${undefined}
        ${null}                | ${mockEnvironmentPath} | ${undefined}
        ${mockEnvironmentName} | ${null}                | ${undefined}
        ${mockEnvironmentName} | ${mockEnvironmentPath} | ${expect.any(Object)}
      `(
        'when environmentName is $environmentName and environmentPath is $environmentPath',
        ({ environmentName, environmentPath, isVisible }) => {
          it(`${isVisible ? 'renders' : 'does not render'} the button`, () => {
            createComponent({ environmentName, environmentPath });

            expect(findDropdownItemWithText(`View on ${environmentName}`)).toEqual(isVisible);
          });
        },
      );

      it('renders the correct props', () => {
        createComponent({
          environmentName: mockEnvironmentName,
          environmentPath: mockEnvironmentPath,
        });

        expect(findEnvironmentItem().props('item')).toMatchObject({
          text: `View on ${mockEnvironmentName}`,
          href: mockEnvironmentPath,
        });
      });
    });

    describe('events', () => {
      it('emits copy event when overrideCopy is true', () => {
        createComponent({
          overrideCopy: true,
        });

        findCopyFileContentItem().vm.$emit('action');
        expect(wrapper.emitted('copy')).toHaveLength(1);
      });

      it('does not emit copy event when overrideCopy is false', () => {
        createComponent({
          overrideCopy: false,
        });

        findCopyFileContentItem().vm.$emit('action');
        expect(wrapper.emitted('copy')).toBeUndefined();
      });
    });
  });
});
