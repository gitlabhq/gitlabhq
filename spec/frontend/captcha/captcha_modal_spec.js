import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import CaptchaModal from '~/captcha/captcha_modal.vue';
import { initRecaptchaScript } from '~/captcha/init_recaptcha_script';

jest.mock('~/captcha/init_recaptcha_script');

describe('Captcha Modal', () => {
  let wrapper;
  let grecaptcha;

  const captchaSiteKey = 'abc123';
  const showSpy = jest.fn();
  const hideSpy = jest.fn();

  function createComponent({ props = {} } = {}) {
    wrapper = shallowMount(CaptchaModal, {
      propsData: {
        captchaSiteKey,
        ...props,
      },
      stubs: {
        GlModal: stubComponent(GlModal, {
          methods: {
            show: showSpy,
            hide: hideSpy,
          },
        }),
      },
    });
  }

  const findGlModal = () => wrapper.findComponent(GlModal);

  beforeEach(() => {
    grecaptcha = {
      render: jest.fn(),
      reset: jest.fn(),
    };

    initRecaptchaScript.mockResolvedValue(grecaptcha);
  });

  describe('rendering', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders', () => {
      expect(findGlModal().exists()).toBe(true);
    });

    it('assigns the modal a unique ID', () => {
      const firstInstanceModalId = findGlModal().props('modalId');
      createComponent();
      const secondInstanceModalId = findGlModal().props('modalId');
      expect(firstInstanceModalId).not.toEqual(secondInstanceModalId);
    });
  });

  describe('functionality', () => {
    describe('when modal is shown', () => {
      describe('when initRecaptchaScript promise resolves successfully', () => {
        beforeEach(() => {
          createComponent({ props: { needsCaptchaResponse: true } });
          findGlModal().vm.$emit('shown');
        });

        it('shows modal', () => {
          expect(showSpy).toHaveBeenCalled();
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

          it('hides modal with null trigger', () => {
            // Assert that hide is called with zero args, so that we don't trigger the logic
            // for hiding the modal via cancel, esc, headerclose, etc, without a captcha response
            expect(hideSpy).toHaveBeenCalledWith();
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
              findGlModal().vm.$emit('hide', bvModalEvent);
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
          createComponent({
            props: { needsCaptchaResponse: true },
          });

          initRecaptchaScript.mockImplementation(() => Promise.reject(fakeError));
          jest.spyOn(console, 'error').mockImplementation();

          findGlModal().vm.$emit('shown');
        });

        it('emits receivedCaptchaResponse exactly once with null', () => {
          expect(wrapper.emitted('receivedCaptchaResponse')).toEqual([[null]]);
        });

        it('hides modal with null trigger', () => {
          // Assert that hide is called with zero args, so that we don't trigger the logic
          // for hiding the modal via cancel, esc, headerclose, etc, without a captcha response
          expect(hideSpy).toHaveBeenCalledWith();
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

  describe('when showModal is false', () => {
    beforeEach(() => {
      createComponent({ props: { showModal: false, needsCaptchaResponse: true } });
    });

    it('does not render the modal', () => {
      expect(findGlModal().exists()).toBe(false);
    });

    it('renders captcha', () => {
      expect(grecaptcha.render).toHaveBeenCalledWith(wrapper.vm.$refs.captcha, {
        sitekey: captchaSiteKey,
        callback: expect.any(Function),
      });
    });
  });

  describe('needsCaptchaResponse watcher', () => {
    describe('when showModal is true', () => {
      beforeEach(() => {
        createComponent({ props: { showModal: true, needsCaptchaResponse: false } });
        wrapper.setProps({ needsCaptchaResponse: true });
      });

      it('shows modal', () => {
        expect(showSpy).toHaveBeenCalled();
      });
    });

    describe('when showModal is false', () => {
      beforeEach(() => {
        createComponent({ props: { showModal: false, needsCaptchaResponse: false } });
        wrapper.setProps({ needsCaptchaResponse: true });
      });

      it('does not render the modal', () => {
        expect(findGlModal().exists()).toBe(false);
      });

      it('renders captcha', () => {
        expect(grecaptcha.render).toHaveBeenCalledWith(wrapper.vm.$refs.captcha, {
          sitekey: captchaSiteKey,
          callback: expect.any(Function),
        });
      });
    });
  });

  describe('resetSession watcher', () => {
    beforeEach(() => {
      createComponent({ props: { showModal: false, needsCaptchaResponse: true } });
    });

    it('calls reset when resetSession is true', async () => {
      await waitForPromises();
      await wrapper.setProps({ resetSession: true });

      expect(grecaptcha.reset).toHaveBeenCalled();
    });
  });
});
