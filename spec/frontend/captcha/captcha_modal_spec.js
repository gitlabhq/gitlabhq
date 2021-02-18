import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { stubComponent } from 'helpers/stub_component';
import CaptchaModal from '~/captcha/captcha_modal.vue';
import { initRecaptchaScript } from '~/captcha/init_recaptcha_script';

jest.mock('~/captcha/init_recaptcha_script');

describe('Captcha Modal', () => {
  let wrapper;
  let modal;
  let grecaptcha;

  const captchaSiteKey = 'abc123';

  function createComponent({ props = {} } = {}) {
    wrapper = shallowMount(CaptchaModal, {
      propsData: {
        captchaSiteKey,
        ...props,
      },
      stubs: {
        GlModal: stubComponent(GlModal),
      },
    });
  }

  beforeEach(() => {
    grecaptcha = {
      render: jest.fn(),
    };

    initRecaptchaScript.mockResolvedValue(grecaptcha);
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findGlModal = () => {
    const glModal = wrapper.find(GlModal);

    jest.spyOn(glModal.vm, 'show').mockImplementation(() => glModal.vm.$emit('shown'));
    jest
      .spyOn(glModal.vm, 'hide')
      .mockImplementation(() => glModal.vm.$emit('hide', { trigger: '' }));

    return glModal;
  };

  const showModal = () => {
    wrapper.setProps({ needsCaptchaResponse: true });
  };

  beforeEach(() => {
    createComponent();
    modal = findGlModal();
  });

  describe('rendering', () => {
    it('renders', () => {
      expect(modal.exists()).toBe(true);
    });

    it('assigns the modal a unique ID', () => {
      const firstInstanceModalId = modal.props('modalId');
      createComponent();
      const secondInstanceModalId = findGlModal().props('modalId');
      expect(firstInstanceModalId).not.toEqual(secondInstanceModalId);
    });
  });

  describe('functionality', () => {
    describe('when modal is shown', () => {
      describe('when initRecaptchaScript promise resolves successfully', () => {
        beforeEach(async () => {
          showModal();

          await nextTick();
        });

        it('shows modal', async () => {
          expect(findGlModal().vm.show).toHaveBeenCalled();
        });

        it('renders window.grecaptcha', () => {
          expect(grecaptcha.render).toHaveBeenCalledWith(wrapper.vm.$refs.captcha, {
            sitekey: captchaSiteKey,
            callback: expect.any(Function),
          });
        });

        describe('then the user solves the captcha', () => {
          const captchaResponse = 'a captcha response';

          beforeEach(() => {
            // simulate the grecaptcha library invoking the callback
            const { callback } = grecaptcha.render.mock.calls[0][1];
            callback(captchaResponse);
          });

          it('emits receivedCaptchaResponse exactly once with the captcha response', () => {
            expect(wrapper.emitted('receivedCaptchaResponse')).toEqual([[captchaResponse]]);
          });

          it('hides modal with null trigger', async () => {
            // Assert that hide is called with zero args, so that we don't trigger the logic
            // for hiding the modal via cancel, esc, headerclose, etc, without a captcha response
            expect(modal.vm.hide).toHaveBeenCalledWith();
          });
        });

        describe('then the user hides the modal without solving the captcha', () => {
          // Even though we don't explicitly check for these trigger values, these are the
          // currently supported ones which can be emitted.
          // See https://bootstrap-vue.org/docs/components/modal#prevent-closing
          describe.each`
            trigger          | expected
            ${'cancel'}      | ${[[null]]}
            ${'esc'}         | ${[[null]]}
            ${'backdrop'}    | ${[[null]]}
            ${'headerclose'} | ${[[null]]}
          `('using the $trigger trigger', ({ trigger, expected }) => {
            beforeEach(() => {
              const bvModalEvent = {
                trigger,
              };
              modal.vm.$emit('hide', bvModalEvent);
            });

            it(`emits receivedCaptchaResponse with ${JSON.stringify(expected)}`, () => {
              expect(wrapper.emitted('receivedCaptchaResponse')).toEqual(expected);
            });
          });
        });
      });

      describe('when initRecaptchaScript promise rejects', () => {
        const fakeError = {};

        beforeEach(() => {
          initRecaptchaScript.mockImplementation(() => Promise.reject(fakeError));

          jest.spyOn(console, 'error').mockImplementation();

          showModal();
        });

        it('emits receivedCaptchaResponse exactly once with null', () => {
          expect(wrapper.emitted('receivedCaptchaResponse')).toEqual([[null]]);
        });

        it('hides modal with null trigger', async () => {
          // Assert that hide is called with zero args, so that we don't trigger the logic
          // for hiding the modal via cancel, esc, headerclose, etc, without a captcha response
          expect(modal.vm.hide).toHaveBeenCalledWith();
        });

        it('calls console.error with a message and the exception', () => {
          // eslint-disable-next-line no-console
          expect(console.error).toHaveBeenCalledWith(
            expect.stringMatching(/exception.*captcha/),
            fakeError,
          );
        });
      });
    });
  });
});
