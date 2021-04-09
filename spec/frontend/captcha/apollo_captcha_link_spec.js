import { ApolloLink, Observable } from 'apollo-link';

import { apolloCaptchaLink } from '~/captcha/apollo_captcha_link';
import UnsolvedCaptchaError from '~/captcha/unsolved_captcha_error';
import { waitForCaptchaToBeSolved } from '~/captcha/wait_for_captcha_to_be_solved';

jest.mock('~/captcha/wait_for_captcha_to_be_solved');

describe('apolloCaptchaLink', () => {
  const SPAM_LOG_ID = 'SPAM_LOG_ID';
  const CAPTCHA_SITE_KEY = 'CAPTCHA_SITE_KEY';
  const CAPTCHA_RESPONSE = 'CAPTCHA_RESPONSE';

  const SUCCESS_RESPONSE = {
    data: {
      user: {
        id: 3,
        name: 'foo',
      },
    },
    errors: [],
  };

  const NON_CAPTCHA_ERROR_RESPONSE = {
    data: {
      user: null,
    },
    errors: [
      {
        message: 'Something is severely wrong with your query.',
        path: ['user'],
        locations: [{ line: 2, column: 3 }],
        extensions: {
          message: 'Object not found',
          type: 2,
        },
      },
    ],
  };

  const SPAM_ERROR_RESPONSE = {
    data: {
      user: null,
    },
    errors: [
      {
        message: 'Your Query was detected to be spam.',
        path: ['user'],
        locations: [{ line: 2, column: 3 }],
        extensions: {
          spam: true,
        },
      },
    ],
  };

  const CAPTCHA_ERROR_RESPONSE = {
    data: {
      user: null,
    },
    errors: [
      {
        message: 'This is an unrelated error, captcha should still work despite this.',
        path: ['user'],
        locations: [{ line: 2, column: 3 }],
      },
      {
        message: 'You need to solve a Captcha.',
        path: ['user'],
        locations: [{ line: 2, column: 3 }],
        extensions: {
          spam: true,
          needs_captcha_response: true,
          captcha_site_key: CAPTCHA_SITE_KEY,
          spam_log_id: SPAM_LOG_ID,
        },
      },
    ],
  };

  let link;

  let mockLinkImplementation;
  let mockContext;

  const setupLink = (...responses) => {
    mockLinkImplementation = jest.fn().mockImplementation(() => {
      return Observable.of(responses.shift());
    });
    link = ApolloLink.from([apolloCaptchaLink, new ApolloLink(mockLinkImplementation)]);
  };

  function mockOperation() {
    mockContext = jest.fn();
    return { operationName: 'operation', variables: {}, setContext: mockContext };
  }

  it('successful responses are passed through', (done) => {
    setupLink(SUCCESS_RESPONSE);
    link.request(mockOperation()).subscribe((result) => {
      expect(result).toEqual(SUCCESS_RESPONSE);
      expect(mockLinkImplementation).toHaveBeenCalledTimes(1);
      expect(waitForCaptchaToBeSolved).not.toHaveBeenCalled();
      done();
    });
  });

  it('non-spam related errors are passed through', (done) => {
    setupLink(NON_CAPTCHA_ERROR_RESPONSE);
    link.request(mockOperation()).subscribe((result) => {
      expect(result).toEqual(NON_CAPTCHA_ERROR_RESPONSE);
      expect(mockLinkImplementation).toHaveBeenCalledTimes(1);
      expect(mockContext).not.toHaveBeenCalled();
      expect(waitForCaptchaToBeSolved).not.toHaveBeenCalled();
      done();
    });
  });

  it('unresolvable spam errors are passed through', (done) => {
    setupLink(SPAM_ERROR_RESPONSE);
    link.request(mockOperation()).subscribe((result) => {
      expect(result).toEqual(SPAM_ERROR_RESPONSE);
      expect(mockLinkImplementation).toHaveBeenCalledTimes(1);
      expect(mockContext).not.toHaveBeenCalled();
      expect(waitForCaptchaToBeSolved).not.toHaveBeenCalled();
      done();
    });
  });

  describe('resolvable spam errors', () => {
    it('re-submits request with spam headers if the captcha modal was solved correctly', (done) => {
      waitForCaptchaToBeSolved.mockResolvedValue(CAPTCHA_RESPONSE);
      setupLink(CAPTCHA_ERROR_RESPONSE, SUCCESS_RESPONSE);
      link.request(mockOperation()).subscribe((result) => {
        expect(result).toEqual(SUCCESS_RESPONSE);
        expect(waitForCaptchaToBeSolved).toHaveBeenCalledWith(CAPTCHA_SITE_KEY);
        expect(mockContext).toHaveBeenCalledWith({
          headers: {
            'X-GitLab-Captcha-Response': CAPTCHA_RESPONSE,
            'X-GitLab-Spam-Log-Id': SPAM_LOG_ID,
          },
        });
        expect(mockLinkImplementation).toHaveBeenCalledTimes(2);
        done();
      });
    });

    it('throws error if the captcha modal was not solved correctly', (done) => {
      const error = new UnsolvedCaptchaError();
      waitForCaptchaToBeSolved.mockRejectedValue(error);

      setupLink(CAPTCHA_ERROR_RESPONSE, SUCCESS_RESPONSE);
      link.request(mockOperation()).subscribe({
        next: done.catch,
        error: (result) => {
          expect(result).toEqual(error);
          expect(waitForCaptchaToBeSolved).toHaveBeenCalledWith(CAPTCHA_SITE_KEY);
          expect(mockContext).not.toHaveBeenCalled();
          expect(mockLinkImplementation).toHaveBeenCalledTimes(1);
          done();
        },
      });
    });
  });
});
