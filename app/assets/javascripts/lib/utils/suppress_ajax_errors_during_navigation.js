/**
 * An Axios error interceptor that suppresses AJAX errors caused
 * by the request being cancelled when the user navigates to a new page
 */
export default (err, isUserNavigating) => {
  if (isUserNavigating && err.code === 'ECONNABORTED') {
    // If the user is navigating away from the current page,
    // prevent .then() and .catch() handlers from being
    // called by returning a Promise that never resolves
    return new Promise(() => {});
  }

  // The error is not related to browser navigation,
  // so propagate the error
  return Promise.reject(err);
};
