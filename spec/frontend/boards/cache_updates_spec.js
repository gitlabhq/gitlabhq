import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { setError } from '~/boards/graphql/cache_updates';
import { defaultClient } from '~/graphql_shared/issuable_client';
import setErrorMutation from '~/boards/graphql/client/set_error.mutation.graphql';

describe('setError', () => {
  let sentryCaptureExceptionSpy;
  const errorMessage = 'Error';
  const error = new Error(errorMessage);

  beforeEach(() => {
    jest.spyOn(defaultClient, 'mutate').mockResolvedValue();
    sentryCaptureExceptionSpy = jest.spyOn(Sentry, 'captureException');
  });

  it('calls setErrorMutation and capture Sentry error', () => {
    setError({ message: errorMessage, error });

    expect(defaultClient.mutate).toHaveBeenCalledWith({
      mutation: setErrorMutation,
      variables: { error: errorMessage },
    });

    expect(sentryCaptureExceptionSpy).toHaveBeenCalledWith(error);
  });

  it('does not capture Sentry error when captureError is false', () => {
    setError({ message: errorMessage, error, captureError: false });

    expect(defaultClient.mutate).toHaveBeenCalledWith({
      mutation: setErrorMutation,
      variables: { error: errorMessage },
    });

    expect(sentryCaptureExceptionSpy).not.toHaveBeenCalled();
  });
});
