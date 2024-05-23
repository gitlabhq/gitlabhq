import { shallowMount } from '@vue/test-utils';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import CodeInstruction from '~/vue_shared/components/registry/code_instruction.vue';

jest.mock('lodash/uniqueId', () => (prefix) => (prefix ? `${prefix}1` : 1));

describe('Package code instruction', () => {
  let wrapper;

  const defaultProps = {
    instruction: 'npm i @my-package',
    copyText: 'Copy npm install command',
  };

  function createComponent(props = {}) {
    wrapper = shallowMount(CodeInstruction, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  }

  const findCopyButton = () => wrapper.findComponent(ClipboardButton);
  const findInputElement = () => wrapper.find('[data-testid="instruction-input"]');
  const findMultilineInstruction = () => wrapper.find('[data-testid="multiline-instruction"]');

  describe('single line', () => {
    beforeEach(() =>
      createComponent({
        label: 'foo_label',
      }),
    );

    it('to match the default snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('multiline', () => {
    beforeEach(() =>
      createComponent({
        instruction: 'this is some\nmultiline text',
        copyText: 'Copy the command',
        label: 'foo_label',
        multiline: true,
      }),
    );

    it('to match the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('tracking', () => {
    let eventSpy;
    const trackingAction = 'test_action';
    const trackingLabel = 'foo_label';

    beforeEach(() => {
      eventSpy = mockTracking(undefined, undefined, jest.spyOn);
    });

    afterEach(() => {
      unmockTracking();
    });

    it('should not track when no trackingAction is provided', () => {
      createComponent();
      findCopyButton().trigger('click');

      expect(eventSpy).toHaveBeenCalledTimes(0);
    });

    describe('when trackingAction is provided for single line', () => {
      beforeEach(() =>
        createComponent({
          trackingAction,
          trackingLabel,
        }),
      );

      it('should track when copying from the input', () => {
        findInputElement().trigger('copy');

        expect(eventSpy).toHaveBeenCalledWith(undefined, trackingAction, {
          label: trackingLabel,
        });
      });

      it('should track when the copy button is pressed', () => {
        findCopyButton().trigger('click');

        expect(eventSpy).toHaveBeenCalledWith(undefined, trackingAction, {
          label: trackingLabel,
        });
      });
    });

    describe('when trackingAction is provided for multiline', () => {
      beforeEach(() =>
        createComponent({
          trackingAction,
          trackingLabel,
          multiline: true,
        }),
      );

      it('should track when copying from the multiline pre element', () => {
        findMultilineInstruction().trigger('copy');

        expect(eventSpy).toHaveBeenCalledWith(undefined, trackingAction, {
          label: trackingLabel,
        });
      });
    });
  });
});
