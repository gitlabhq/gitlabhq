import { nextTick } from 'vue';
import CaptchaModal from '~/captcha/captcha_modal.vue';
import { waitForCaptchaToBeSolved } from '~/captcha/wait_for_captcha_to_be_solved';

jest.mock('~/captcha/captcha_modal.vue', () => ({
  mounted: jest.fn(),
  render(h) {
    return h('div', { attrs: { id: 'mock-modal' } });
  },
}));

describe('waitForCaptchaToBeSolved', () => {
  const response = 'CAPTCHA_RESPONSE';

  const findModal = () => document.querySelector('#mock-modal');

  it('opens a modal, resolves with captcha response on success', async () => {
    CaptchaModal.mounted.mockImplementationOnce(function mounted() {
      return nextTick().then(() => {
        this.$emit('receivedCaptchaResponse', response);
        this.$emit('hidden');
      });
    });

    expect(findModal()).toBeNull();

    const promise = waitForCaptchaToBeSolved('FOO');

    expect(findModal()).not.toBeNull();

    const result = await promise;
    expect(result).toEqual(response);

    expect(findModal()).toBeNull();
    expect(document.body.innerHTML).toEqual('');
  });

  it("opens a modal, rejects with error in case the captcha isn't solved", async () => {
    CaptchaModal.mounted.mockImplementationOnce(function mounted() {
      return nextTick().then(() => {
        this.$emit('receivedCaptchaResponse', null);
        this.$emit('hidden');
      });
    });

    expect(findModal()).toBeNull();

    const promise = waitForCaptchaToBeSolved('FOO');

    expect(findModal()).not.toBeNull();

    await expect(promise).rejects.toThrow(/You must solve the CAPTCHA in order to submit/);

    expect(findModal()).toBeNull();
    expect(document.body.innerHTML).toEqual('');
  });
});
