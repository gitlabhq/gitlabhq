import { mount } from '@vue/test-utils';
import CodeInstruction from '~/packages/details/components/code_instruction.vue';
import { TrackingLabels } from '~/packages/details/constants';
import Tracking from '~/tracking';

describe('Package code instruction', () => {
  let wrapper;

  const defaultProps = {
    instruction: 'npm i @my-package',
    copyText: 'Copy npm install command',
  };

  function createComponent(props = {}) {
    wrapper = mount(CodeInstruction, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  }

  const findInstructionInput = () => wrapper.find('.js-instruction-input');
  const findInstructionPre = () => wrapper.find('.js-instruction-pre');
  const findInstructionButton = () => wrapper.find('.js-instruction-button');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('single line', () => {
    beforeEach(() => createComponent());

    it('to match the default snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('multiline', () => {
    beforeEach(() =>
      createComponent({
        instruction: 'this is some\nmultiline text',
        copyText: 'Copy the command',
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
    const label = TrackingLabels.CODE_INSTRUCTION;

    beforeEach(() => {
      eventSpy = jest.spyOn(Tracking, 'event');
    });

    it('should not track when no trackingAction is provided', () => {
      createComponent();
      findInstructionButton().trigger('click');

      expect(eventSpy).toHaveBeenCalledTimes(0);
    });

    describe('when trackingAction is provided for single line', () => {
      beforeEach(() =>
        createComponent({
          trackingAction,
        }),
      );

      it('should track when copying from the input', () => {
        findInstructionInput().trigger('copy');

        expect(eventSpy).toHaveBeenCalledWith(undefined, trackingAction, {
          label,
        });
      });

      it('should track when the copy button is pressed', () => {
        findInstructionButton().trigger('click');

        expect(eventSpy).toHaveBeenCalledWith(undefined, trackingAction, {
          label,
        });
      });
    });

    describe('when trackingAction is provided for multiline', () => {
      beforeEach(() =>
        createComponent({
          trackingAction,
          multiline: true,
        }),
      );

      it('should track when copying from the multiline pre element', () => {
        findInstructionPre().trigger('copy');

        expect(eventSpy).toHaveBeenCalledWith(undefined, trackingAction, {
          label,
        });
      });
    });
  });
});
