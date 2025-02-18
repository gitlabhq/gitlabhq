import { shallowMount } from '@vue/test-utils';
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import BlobDefaultActionsGroup from '~/repository/components/header_area/blob_default_actions_group.vue';
import { blobControlsDataMock } from '../../mock_data';

const mockBlobHash = 'foo-bar';
const mockEnvironmentName = 'my.testing.environment';
const mockEnvironmentPath = 'https://my.testing.environment';
const blobInfoMock = blobControlsDataMock.repository.blobs.nodes[0];

describe('Blob Default Actions Group', () => {
  let wrapper;

  const createComponent = (props = {}, provide = {}) => {
    wrapper = shallowMount(BlobDefaultActionsGroup, {
      propsData: {
        blobHash: mockBlobHash,
        activeViewerType: 'simple',
        hasRenderError: false,
        isBinary: false,
        isEmpty: false,
        canDownloadCode: true,
        overrideCopy: false,
        ...props,
      },
      provide: {
        blobHash: mockBlobHash,
        canDownloadCode: true,
        blobInfo: {
          ...blobInfoMock,
          ...provide.blobInfo,
        },
        ...provide,
      },
    });
  };

  const findDropdownItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findDropdownItemWithText = (text) =>
    findDropdownItems().wrappers.find((x) => x.props('item').text === text);
  const findCopyFileContentItem = () => findDropdownItemWithText('Copy file contents');
  const findViewRawItem = () => findDropdownItemWithText('Open raw');
  const findDownloadItem = () => findDropdownItemWithText('Download');
  const findEnvironmentItem = () =>
    findDropdownItemWithText(`View on ${blobInfoMock.environmentFormattedExternalUrl}`);

  beforeEach(() => {
    createComponent();
  });

  describe('Copy file contents', () => {
    it('renders "Copy file contents" button as enabled if the viewer is Simple', () => {
      expect(findCopyFileContentItem().props('item')).toMatchObject({
        extraAttrs: { disabled: false },
      });
    });

    it('renders "Copy file contents" button as disabled if the viewer is Rich', () => {
      createComponent({ activeViewerType: 'rich' });

      expect(findCopyFileContentItem().props('item')).toMatchObject({
        extraAttrs: { disabled: true },
      });
    });

    it('does not render the copy button if a rendering error is set', () => {
      createComponent({ hasRenderError: true });

      expect(findCopyFileContentItem()).toBeUndefined();
    });
  });

  describe('Open raw', () => {
    it('renders with correct props', () => {
      expect(findViewRawItem().props('item')).toMatchObject({
        href: 'https://testing.com/flightjs/flight/snippets/51/raw',
      });
    });
  });

  it('does not render the Copy and view Raw button if isBinary is set to true', () => {
    createComponent({ isBinary: true });

    expect(findCopyFileContentItem()).toBeUndefined();
    expect(findViewRawItem()).toBeUndefined();
  });

  describe('Download', () => {
    it('renders with correct props', () => {
      expect(findDownloadItem().props('item')).toMatchObject({
        href: 'https://testing.com/flightjs/flight/snippets/51/raw?inline=false',
      });
    });

    it('does not render the download button if canDownloadCode is set to false', () => {
      createComponent({}, { canDownloadCode: false });

      expect(findDownloadItem()).toBeUndefined();
    });
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
          createComponent(
            {},
            {
              blobInfo: {
                ...blobInfoMock,
                environmentFormattedExternalUrl: environmentName,
                environmentExternalUrlForRouteMap: environmentPath,
              },
            },
          );

          expect(findEnvironmentItem()).toEqual(isVisible);
        });
      },
    );

    it('renders the correct props', () => {
      createComponent(
        {},
        {
          blobInfo: {
            environmentFormattedExternalUrl: mockEnvironmentName,
            environmentExternalUrlForRouteMap: mockEnvironmentPath,
          },
        },
      );

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
