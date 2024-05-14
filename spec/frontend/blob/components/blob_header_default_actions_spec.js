import { GlButtonGroup, GlButton } from '@gitlab/ui';
import BlobHeaderActions from '~/blob/components/blob_header_default_actions.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  BTN_COPY_CONTENTS_TITLE,
  BTN_DOWNLOAD_TITLE,
  BTN_RAW_TITLE,
  RICH_BLOB_VIEWER,
} from '~/blob/components/constants';
import { Blob, mockEnvironmentName, mockEnvironmentPath } from './mock_data';

describe('Blob Header Default Actions', () => {
  let wrapper;
  let btnGroup;
  let buttons;

  const blobHash = 'foo-bar';

  function createComponent(propsData = {}, provided = {}) {
    wrapper = shallowMountExtended(BlobHeaderActions, {
      provide: {
        blobHash,
        ...provided,
      },
      propsData: {
        rawPath: Blob.rawPath,
        ...propsData,
      },
    });
  }

  beforeEach(() => {
    createComponent();
    btnGroup = wrapper.findComponent(GlButtonGroup);
    buttons = wrapper.findAllComponents(GlButton);
  });

  describe('renders', () => {
    const findCopyButton = () => wrapper.findByTestId('copy-contents-button');
    const findViewRawButton = () => wrapper.findByTestId('viewRawButton');
    const findDownloadButton = () => wrapper.findByTestId('download-button');

    it('gl-button-group component', () => {
      expect(btnGroup.exists()).toBe(true);
    });

    it('exactly 3 buttons with predefined actions', () => {
      expect(buttons.length).toBe(3);
      [BTN_COPY_CONTENTS_TITLE, BTN_RAW_TITLE, BTN_DOWNLOAD_TITLE].forEach((title, i) => {
        expect(buttons.at(i).attributes('title')).toBe(title);
      });
    });

    it('correct href attribute on RAW button', () => {
      expect(buttons.at(1).attributes('href')).toBe(Blob.rawPath);
    });

    it('correct href attribute on Download button', () => {
      expect(buttons.at(2).attributes('href')).toBe(`${Blob.rawPath}?inline=false`);
    });

    it('does not render "Copy file contents" button as disables if the viewer is Simple', () => {
      expect(buttons.at(0).attributes('disabled')).toBeUndefined();
    });

    it('renders "Copy file contents" button as disables if the viewer is Rich', () => {
      createComponent({
        activeViewer: RICH_BLOB_VIEWER,
      });
      buttons = wrapper.findAllComponents(GlButton);

      expect(buttons.at(0).attributes('disabled')).toBeDefined();
    });

    it('does not render the copy button if a rendering error is set', () => {
      createComponent({
        hasRenderError: true,
      });

      expect(findCopyButton().exists()).toBe(false);
    });

    it('does not render the copy and view raw button if isBinary is set to true', () => {
      createComponent({ isBinary: true });

      expect(findCopyButton().exists()).toBe(false);
      expect(findViewRawButton().exists()).toBe(false);
    });

    it('does not render the download button if canDownloadCode is set to false', () => {
      createComponent({}, { canDownloadCode: false });

      expect(findDownloadButton().exists()).toBe(false);
    });

    it('emits a copy event if overrideCopy is set to true', () => {
      createComponent({ overrideCopy: true });
      findCopyButton().vm.$emit('click');

      expect(wrapper.emitted('copy')).toHaveLength(1);
    });
  });

  describe('view on environment button', () => {
    const findEnvironmentButton = () => wrapper.findByTestId('environment');

    it.each`
      environmentName        | environmentPath        | isVisible
      ${null}                | ${null}                | ${false}
      ${null}                | ${mockEnvironmentPath} | ${false}
      ${mockEnvironmentName} | ${null}                | ${false}
      ${mockEnvironmentName} | ${mockEnvironmentPath} | ${true}
    `(
      'when environmentName is $environmentName and environmentPath is $environmentPath',
      ({ environmentName, environmentPath, isVisible }) => {
        createComponent({ environmentName, environmentPath });

        expect(findEnvironmentButton().exists()).toBe(isVisible);
      },
    );

    it('renders the correct attributes', () => {
      createComponent({
        environmentName: mockEnvironmentName,
        environmentPath: mockEnvironmentPath,
      });

      expect(findEnvironmentButton().attributes()).toMatchObject({
        title: `View on ${mockEnvironmentName}`,
        href: mockEnvironmentPath,
      });

      expect(findEnvironmentButton().props('icon')).toBe('external-link');
    });
  });
});
