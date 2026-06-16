import { GlButtonGroup, GlButton, GlDisclosureDropdown } from '@gitlab/ui';
import BlobHeaderActions from '~/blob/components/blob_header_default_actions.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  BTN_COPY_CONTENTS_TITLE,
  BTN_DOWNLOAD_TITLE,
  BTN_DOWNLOAD_AS_MARKDOWN_TITLE,
  BTN_DOWNLOAD_AS_PDF_TITLE,
  BTN_RAW_TITLE,
  RICH_BLOB_VIEWER,
} from '~/blob/components/constants';
import { Blob, mockEnvironmentName, mockEnvironmentPath } from './mock_data';

describe('Blob Header Default Actions', () => {
  let wrapper;
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
    buttons = wrapper.findAllComponents(GlButton);
  });

  describe('renders', () => {
    const findButtonGroup = () => wrapper.findComponent(GlButtonGroup);
    const findCopyButton = () => wrapper.findByTestId('copy-contents-button');
    const findViewRawButton = () => wrapper.findByTestId('viewRawButton');
    const findDownloadButton = () => wrapper.findByTestId('download-button');
    const findOpenNewWindowButton = () => wrapper.findByTestId('open-new-window-button');

    it('gl-button-group component', () => {
      expect(findButtonGroup().exists()).toBe(true);
    });

    it('exactly 3 buttons with predefined actions', () => {
      expect(buttons).toHaveLength(3);
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

    it('renders "Open in new window" button with inline=true in URL for PDF files', () => {
      const pdfPath = '/namespace/project/-/raw/main/sample.pdf';
      createComponent(
        { rawPath: pdfPath },
        { fileType: 'application/pdf', blobHash: 'abc123', canDownloadCode: true },
      );

      const button = findOpenNewWindowButton();
      expect(button.exists()).toBe(true);
      expect(button.attributes('href')).toEqual(
        'http://test.host/namespace/project/-/raw/main/sample.pdf?inline=true',
      );
    });

    it('does not render button for any non-PDF files', () => {
      const nonPdfFiles = ['file.txt', 'file.docx', 'image.jpg', 'archive.zip'];
      nonPdfFiles.forEach((path) => {
        createComponent(
          { rawPath: `/namespace/project/-/raw/main/${path}` },
          { fileType: 'text/plain', blobHash: 'abc123', canDownloadCode: true },
        );
        expect(findOpenNewWindowButton().exists()).toBe(false);
      });
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

  describe('default actions layout', () => {
    it('hides default actions for mobile layout', () => {
      createComponent();

      expect(wrapper.findComponent(GlButtonGroup).attributes('class')).toBe(
        'gl-hidden @sm/panel:gl-inline-flex',
      );
    });
  });

  describe('download dropdown', () => {
    const markdownRawPath = '/namespace/project/-/raw/main/README.md';
    const findDownloadDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
    const findDownloadButton = () => wrapper.findByTestId('download-button');

    describe('when file is markdown', () => {
      beforeEach(() => {
        createComponent({ rawPath: markdownRawPath });
      });

      it('renders the download dropdown instead of the plain download button', () => {
        expect(findDownloadDropdown().exists()).toBe(true);
        expect(findDownloadButton().exists()).toBe(false);
      });

      it('passes two items to the dropdown', () => {
        expect(findDownloadDropdown().props('items')).toHaveLength(2);
      });

      it('first item is Download as Markdown with correct href', () => {
        const [markdownItem] = findDownloadDropdown().props('items');

        expect(markdownItem.text).toBe(BTN_DOWNLOAD_AS_MARKDOWN_TITLE);
        expect(markdownItem.href).toContain('inline=false');
      });

      it('second item is Print as PDF with an action function', () => {
        const [, pdfItem] = findDownloadDropdown().props('items');

        expect(pdfItem.text).toBe(BTN_DOWNLOAD_AS_PDF_TITLE);
        expect(typeof pdfItem.action).toBe('function');
      });
    });

    describe('when file is not markdown', () => {
      it('does not render the dropdown', () => {
        createComponent({ rawPath: '/namespace/project/-/raw/main/file.txt' });

        expect(findDownloadDropdown().exists()).toBe(false);
        expect(findDownloadButton().exists()).toBe(true);
      });
    });

    describe('Print as PDF action', () => {
      beforeEach(() => {
        document.body.innerHTML = `
          <img src="https://example.com/image.png" loading="lazy" />
          <details><summary>Summary</summary><p>Content</p></details>
        `;
        jest.spyOn(window, 'print').mockImplementation(() => {});
        createComponent({ rawPath: markdownRawPath });

        const [, pdfItem] = findDownloadDropdown().props('items');
        pdfItem.action();
      });

      afterEach(() => {
        document.body.innerHTML = '';
      });

      it('calls window.print', () => {
        expect(window.print).toHaveBeenCalled();
      });

      it('sets all images to eager loading', () => {
        expect(document.querySelector('img').getAttribute('loading')).toBe('eager');
      });

      it('opens all details elements', () => {
        expect(document.querySelector('details').getAttribute('open')).toBe('');
      });
    });
  });
});
