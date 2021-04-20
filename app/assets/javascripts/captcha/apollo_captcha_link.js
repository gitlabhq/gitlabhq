import { ApolloLink, Observable } from 'apollo-link';

export const apolloCaptchaLink = new ApolloLink((operation, forward) =>
  forward(operation).flatMap((result) => {
    const { errors = [] } = result;

    // Our API will return with a top-level GraphQL error with extensions
    // in case a captcha is required.
    const captchaError = errors.find((e) => e?.extensions?.needs_captcha_response);
    if (captchaError) {
      const captchaSiteKey = captchaError.extensions.captcha_site_key;
      const spamLogId = captchaError.extensions.spam_log_id;

      return new Observable((observer) => {
        import('~/captcha/wait_for_captcha_to_be_solved')
          .then(({ waitForCaptchaToBeSolved }) => waitForCaptchaToBeSolved(captchaSiteKey))
          .then((captchaResponse) => {
            // If the captcha was solved correctly, we re-do our action while setting
            // captcha response headers.
            operation.setContext({
              headers: {
                'X-GitLab-Captcha-Response': captchaResponse,
                'X-GitLab-Spam-Log-Id': spamLogId,
              },
            });
            forward(operation).subscribe(observer);
          })
          .catch((error) => {
            observer.error(error);
            observer.complete();
          });
      });
    }

    return Observable.of(result);
  }),
);
