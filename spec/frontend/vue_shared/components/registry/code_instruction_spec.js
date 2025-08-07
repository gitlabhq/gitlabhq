import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';
import CodeInstruction from '~/vue_shared/components/registry/code_instruction.vue';

jest.mock('lodash/uniqueId', () => (prefix) => (prefix ? `${prefix}1` : 1));

describe('Package code instruction', () => {
  let wrapper;

  const defaultProps = {
    instruction: 'npm i @my-package',
    copyText: 'Copy npm install command',
  };

  function createComponent(props = {}) {
    wrapper = shallowMountExtended(CodeInstruction, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  }

  const findCopyButton = () => wrapper.findComponent(ModalCopyButton);
  const findLabel = () => wrapper.find('label');
  const findInputElement = () => wrapper.findByTestId('instruction-input');
  const findMultilineInstruction = () => wrapper.findByTestId('multiline-instruction');

  describe('single line', () => {
    beforeEach(() =>
      createComponent({
        label: 'foo_label',
      }),
    );

    it('to render label with value', () => {
      expect(findLabel().text()).toBe('foo_label');
      expect(findLabel().attributes('for')).toBe('instruction-input_1');
    });

    it('to render input with value', () => {
      expect(findInputElement().element.value).toBe('npm i @my-package');

      expect(findInputElement().attributes('id')).toBe('instruction-input_1');
      expect(findInputElement().attributes('readonly')).toBeDefined();
    });

    it('to render modal copy button', () => {
      expect(findCopyButton().props()).toMatchObject({
        text: 'npm i @my-package',
        title: 'Copy npm install command',
      });
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
