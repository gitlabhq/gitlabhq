import { GlButton } from '@gitlab/ui';
import { mount, createWrapper as vtuCreateWrapper } from '@vue/test-utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { copyToClipboard } from '~/lib/utils/copy_to_clipboard';
import waitForPromises from 'helpers/wait_for_promises';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

import SimpleCopyButton from '~/vue_shared/components/simple_copy_button.vue';

jest.mock('~/lib/utils/copy_to_clipboard');
jest.mock('~/sentry/sentry_browser_wrapper');

describe('clipboard button', () => {
  let wrapper;
  let rootWrapper;
  let mockToastShow;

  const createWrapper = ({ props, ...options } = {}) => {
    wrapper = mount(SimpleCopyButton, {
      propsData: {
        text: 'copy me',
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      mocks: {
        $toast: { show: mockToastShow },
      },
      ...options,
    });

    rootWrapper = vtuCreateWrapper(wrapper.vm.$root);
  };

  const findButton = () => wrapper.findComponent(GlButton);
  const getTooltip = () => getBinding(findButton().element, 'gl-tooltip');

  const clickButton = async () => {
    findButton().vm.$emit('click');
    await waitForPromises();
  };

  beforeEach(() => {
    mockToastShow = jest.fn();
    copyToClipboard.mockResolvedValue();
  });

  describe('default options', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders a button to copy', () => {
      expect(findButton().props('category')).toBe('secondary');
      expect(findButton().props('size')).toBe('medium');
      expect(findButton().props('variant')).toBe('default');
      expect(findButton().props('icon')).toBe('copy-to-clipboard');

      expect(findButton().attributes('aria-live')).toBe('polite');
      expect(findButton().attributes('aria-label')).toBe('Copy');
    });

    it('configures tooltip', () => {
      expect(getTooltip()).toMatchObject({
        value: { placement: 'top', title: 'Copy' },
      });
    });

    describe('when clicked', () => {
      beforeEach(async () => {
        await clickButton();
      });

      it('copies', () => {
        expect(copyToClipboard).toHaveBeenCalledWith('copy me', wrapper.element);
      });

      it('shows toast', () => {
        expect(mockToastShow).toHaveBeenCalledWith('Copied to clipboard.');
      });

      it('emits "copied" event', () => {
        expect(wrapper.emitted('copied')).toEqual([[]]);
      });
    });

    describe('when on mouseout', () => {
      beforeEach(() => {
        findButton().vm.$emit('mouseout');
      });

      it('hides tooltip', () => {
        expect(rootWrapper.emitted('bv::hide::tooltip')).toEqual([[wrapper.element.id]]);
      });
    });
  });

  describe('customization', () => {
    it('renders a button to copy with other options', () => {
      createWrapper({
        props: {
          category: 'tertiary',
          size: 'small',
          variant: 'confirm',
          icon: 'pencil',
          ariaLabel: 'My aria label',
          title: 'My title',
        },
      });

      expect(findButton().props('category')).toBe('tertiary');
      expect(findButton().props('size')).toBe('small');
      expect(findButton().props('variant')).toBe('confirm');
      expect(findButton().props('icon')).toBe('pencil');

      expect(findButton().attributes('aria-live')).toBe('polite');
      expect(findButton().attributes('aria-label')).toBe('My aria label');

      expect(getTooltip()).toMatchObject({
        value: { title: 'My title' },
      });
    });

    it('shows another toast message', async () => {
      createWrapper({
        props: { toastMessage: 'Copied! Yey!' },
      });
      await clickButton();

      expect(mockToastShow).toHaveBeenCalledWith('Copied! Yey!');
    });

    it('shows no toast message', async () => {
      createWrapper({
        props: { toastMessage: '' },
      });
      await clickButton();

      expect(mockToastShow).not.toHaveBeenCalled();
    });

    it('shows no toast message when the type is not a string', async () => {
      createWrapper({
        props: { toastMessage: true },
      });
      await clickButton();

      expect(mockToastShow).not.toHaveBeenCalled();
    });
  });

  describe('on error', () => {
    beforeEach(() => {
      createWrapper();

      copyToClipboard.mockRejectedValue(new Error('error copying'));
    });

    describe('when clicked', () => {
      beforeEach(async () => {
        await clickButton();
      });

      it('tries to copy', () => {
        expect(copyToClipboard).toHaveBeenCalledWith('copy me', wrapper.element);
      });

      it('does not shows toast', () => {
        expect(mockToastShow).not.toHaveBeenCalled();
      });

      it('emits "error" event and reports to sentry', () => {
        expect(wrapper.emitted('error')).toEqual([[new Error('error copying')]]);

        expect(Sentry.captureException).toHaveBeenCalledWith(new Error('error copying'));
      });
    });
  });
});
