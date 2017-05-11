function errorHandler(error) {
  // eslint-disable-next-line no-console
  console.error('\n\nglobalErrorHandler\n', error, '\n\n');
}

function globalErrorHandler() {
  window.addEventListener('error', errorHandler);
}

export {
  globalErrorHandler as default,
  errorHandler,
};
