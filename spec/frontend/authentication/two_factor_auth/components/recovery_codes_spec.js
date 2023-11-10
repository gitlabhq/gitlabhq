import { GlAlert, GlButton } from '@gitlab/ui';
import { within } from '@testing-library/dom';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import RecoveryCodes, {
  i18n,
} from '~/authentication/two_factor_auth/components/recovery_codes.vue';
import { RECOVERY_CODE_DOWNLOAD_FILENAME } from '~/authentication/two_factor_auth/constants';
import Tracking from '~/tracking';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { MOUSETRAP_COPY_KEYBOARD_SHORTCUT } from '~/lib/mousetrap';
import { codes, codesFormattedString, codesDownloadHref, profileAccountPath } from '../mock_data';

describe('RecoveryCodes', () => {
  let wrapper;

  const createComponent = (options = {}) => {
    wrapper = extendedWrapper(
      mount(RecoveryCodes, {
        propsData: {
          codes,
          profileAccountPath,
          ...options?.propsData,
        },
        ...options,
      }),
    );
  };

  const queryByText = (text, options) => within(wrapper.element).queryByText(text, options);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findRecoveryCodes = () => wrapper.findByTestId('recovery-codes');
  const findCopyButton = () => wrapper.findComponent(ClipboardButton);
  const findButtonByText = (text) =>
    wrapper
      .findAllComponents(GlButton)
      .wrappers.find((buttonWrapper) => buttonWrapper.text() === text);
  const findDownloadButton = () => findButtonByText('Download codes');
  const findPrintButton = () => findButtonByText('Print codes');
  const findProceedButton = () => findButtonByText('Proceed');
  const manuallyCopyRecoveryCodes = () =>
    wrapper.vm.$options.mousetrap.trigger(MOUSETRAP_COPY_KEYBOARD_SHORTCUT);

  beforeEach(() => {
    jest.spyOn(Tracking, 'event');
    createComponent();
  });

  it('renders title', () => {
    expect(queryByText(i18n.pageTitle)).toEqual(expect.any(HTMLElement));
  });

  it('renders alert', () => {
    expect(findAlert().exists()).toBe(true);
    expect(findAlert().text()).toBe(i18n.alertTitle);
  });

  it('renders codes', () => {
    const recoveryCodes = findRecoveryCodes().text();

    codes.forEach((code) => {
      expect(recoveryCodes).toContain(code);
    });
  });

  describe('"Proceed" button', () => {
    it('renders button as disabled', () => {
      const proceedButton = findProceedButton();

      expect(proceedButton.exists()).toBe(true);
      expect(proceedButton.props('disabled')).toBe(true);
      expect(proceedButton.attributes()).toMatchObject({
        title: i18n.proceedButton,
        href: profileAccountPath,
      });
    });

    it('fires Snowplow event', () => {
      expect(findProceedButton().attributes()).toMatchObject({
        'data-track-action': 'click_button',
        'data-track-label': '2fa_recovery_codes_proceed_button',
      });
    });
  });

  describe('"Copy codes" button', () => {
    it('renders button', () => {
      const copyButton = findCopyButton();

      expect(copyButton.exists()).toBe(true);
      expect(copyButton.text()).toBe(i18n.copyButton);
      expect(copyButton.props()).toMatchObject({
        title: i18n.copyButton,
        text: codesFormattedString,
      });
    });

    describe('when button is clicked', () => {
      beforeEach(async () => {
        findCopyButton().trigger('click');

        await nextTick();
      });

      it('enables "Proceed" button', () => {
        expect(findProceedButton().props('disabled')).toBe(false);
      });

      it('fires Snowplow event', () => {
        expect(Tracking.event).toHaveBeenCalledWith(undefined, 'click_button', {
          label: '2fa_recovery_codes_copy_button',
        });
      });
    });
  });

  describe('"Download codes" button', () => {
    it('renders button', () => {
      const downloadButton = findDownloadButton();

      expect(downloadButton.exists()).toBe(true);
      expect(downloadButton.attributes()).toMatchObject({
        title: i18n.downloadButton,
        download: RECOVERY_CODE_DOWNLOAD_FILENAME,
        href: codesDownloadHref,
      });
    });

    describe('when button is clicked', () => {
      beforeEach(async () => {
        const downloadButton = findDownloadButton();
        // jsdom does not support navigating.
        // Since we are clicking an anchor tag there is no way to mock this
        // and we are forced to instead remove the `href` attribute.
        // More info: https://github.com/jsdom/jsdom/issues/2112#issuecomment-663672587
        downloadButton.element.removeAttribute('href');
        downloadButton.trigger('click');

        await nextTick();
      });

      it('enables "Proceed" button', () => {
        expect(findProceedButton().props('disabled')).toBe(false);
      });

      it('fires Snowplow event', () => {
        expect(Tracking.event).toHaveBeenCalledWith(undefined, 'click_button', {
          label: '2fa_recovery_codes_download_button',
        });
      });
    });
  });

  describe('"Print codes" button', () => {
    it('renders button', () => {
      const printButton = findPrintButton();

      expect(printButton.exists()).toBe(true);
      expect(printButton.attributes()).toMatchObject({
        title: i18n.printButton,
      });
    });

    describe('when button is clicked', () => {
      beforeEach(async () => {
        window.print = jest.fn();

        findPrintButton().trigger('click');

        await nextTick();
      });

      it('enables "Proceed" button and opens print dialog', () => {
        expect(findProceedButton().props('disabled')).toBe(false);
        expect(window.print).toHaveBeenCalled();
      });

      it('fires Snowplow event', () => {
        expect(Tracking.event).toHaveBeenCalledWith(undefined, 'click_button', {
          label: '2fa_recovery_codes_print_button',
        });
      });
    });
  });

  describe('when codes are manually copied', () => {
    describe('when selected text is the recovery codes', () => {
      beforeEach(async () => {
        jest.spyOn(window, 'getSelection').mockImplementation(() => ({
          toString: jest.fn(() => codesFormattedString),
        }));

        manuallyCopyRecoveryCodes();

        await nextTick();
      });

      it('enables "Proceed" button', () => {
        expect(findProceedButton().props('disabled')).toBe(false);
      });

      it('fires Snowplow event', () => {
        expect(Tracking.event).toHaveBeenCalledWith(undefined, 'copy_keyboard_shortcut', {
          label: '2fa_recovery_codes_manual_copy',
        });
      });
    });

    describe('when selected text includes the recovery codes', () => {
      beforeEach(() => {
        jest.spyOn(window, 'getSelection').mockImplementation(() => ({
          toString: jest.fn(() => `foo bar ${codesFormattedString}`),
        }));
      });

      it('enables "Proceed" button', async () => {
        manuallyCopyRecoveryCodes();

        await nextTick();

        expect(findProceedButton().props('disabled')).toBe(false);
      });
    });

    describe('when selected text does not include the recovery codes', () => {
      beforeEach(() => {
        jest.spyOn(window, 'getSelection').mockImplementation(() => ({
          toString: jest.fn(() => 'foo bar'),
        }));
      });

      it('keeps "Proceed" button disabled', async () => {
        manuallyCopyRecoveryCodes();

        await nextTick();

        expect(findProceedButton().props('disabled')).toBe(true);
      });
    });
  });
});
