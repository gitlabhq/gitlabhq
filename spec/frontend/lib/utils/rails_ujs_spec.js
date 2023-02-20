import { setHTMLFixture } from 'helpers/fixtures';
import waitForPromises from 'helpers/wait_for_promises';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

beforeAll(async () => {
  // @rails/ujs expects jQuery.ajaxPrefilter to exist if jQuery exists at
  // import time. This is only a problem in tests, since we expose jQuery
  // globally earlier than in production builds. Work around this by pretending
  // that jQuery isn't available *before* we import @rails/ujs.
  delete global.jQuery;

  const { initRails } = await import('~/lib/utils/rails_ujs');
  initRails();
});

function mockXHRResponse({ responseText, responseContentType } = {}) {
  jest
    .spyOn(global.XMLHttpRequest.prototype, 'getResponseHeader')
    .mockReturnValue(responseContentType);

  jest.spyOn(global.XMLHttpRequest.prototype, 'send').mockImplementation(function send() {
    Object.defineProperties(this, {
      readyState: { value: XMLHttpRequest.DONE },
      status: { value: HTTP_STATUS_OK },
      response: { value: responseText },
    });
    this.onreadystatechange();
  });
}

// This is a test to make sure that the patch-package patch correctly disables
// script execution for data-remote attributes.
it('does not perform script execution via data-remote', async () => {
  global.scriptExecutionSpy = jest.fn();

  mockXHRResponse({
    responseText: 'scriptExecutionSpy();',
    responseContentType: 'application/javascript',
  });

  setHTMLFixture(`
    <a href="/foo/evil.js"
       data-remote="true"
       data-method="get"
       data-type="script"
       data-testid="evil-link"
    >XSS</a>
  `);

  const link = document.querySelector('[data-testid="evil-link"]');
  const ajaxSuccessSpy = jest.fn();
  link.addEventListener('ajax:success', ajaxSuccessSpy);

  link.click();

  await waitForPromises();

  // Make sure Rails ajax machinery finished working as expected to avoid false
  // positives
  expect(ajaxSuccessSpy).toHaveBeenCalledTimes(1);

  // If @rails/ujs has been patched correctly, this next assertion should pass.
  //
  // Because it's asserting something didn't happen, it is possible for it to
  // pass for the wrong reason. So, to verify that this test correctly fails
  // when @rails/ujs has not been patched, run:
  //
  //     yarn patch-package --reverse
  //
  // And then re-run this test. The spy should now be called, and correctly
  // fail the test.
  //
  // To restore the patch(es), run:
  //
  //     yarn install
  expect(global.scriptExecutionSpy).not.toHaveBeenCalled();
});
