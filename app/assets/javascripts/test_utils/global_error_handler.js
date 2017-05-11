function errorHandler(error) {
  // eslint-disable-next-line no-console
  console.error('\nglobalErrorHandler\n', JSON.stringify(error), '\n');
}

function globalErrorHandler() {
  window.addEventListener('error', errorHandler);
}

export {
  globalErrorHandler as default,
  errorHandler,
};
