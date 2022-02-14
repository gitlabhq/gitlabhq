import { Observable } from '@apollo/client/core';
import { onError } from '@apollo/client/link/error';
import { isNavigatingAway } from '~/lib/utils/is_navigating_away';

/**
 * Returns an ApolloLink (or null if not enabled) which supresses network
 * errors when the browser is navigating away.
 *
 * @returns {ApolloLink|null}
 */
export const getSuppressNetworkErrorsDuringNavigationLink = () => {
  return onError(({ networkError }) => {
    if (networkError && isNavigatingAway()) {
      // Return an observable that will never notify any subscribers with any
      // values, errors, or completions. This ensures that requests aborted due
      // to navigating away do not trigger any failure behaviour.
      //
      // See '../utils/suppress_ajax_errors_during_navigation.js' for an axios
      // interceptor that performs a similar role.
      return new Observable(() => {});
    }

    // We aren't suppressing anything here, so simply do nothing.
    // The onError helper will forward all values/errors/completions from the
    // underlying request observable to the next link if you return a falsey
    // value.
    //
    // Note that this return statement is technically redundant, but is kept
    // for explicitness.
    return undefined;
  });
};
