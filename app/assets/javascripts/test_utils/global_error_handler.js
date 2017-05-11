function errorHandler(error) {
  // eslint-disable-next-line no-console
  console.error(
    '\nglobalErrorHandler\n',
    error.name,
    error.message,
    error.fileName,
    error.lineNumber,
    error.columnNumber,
    error.stack,
    '\n',
  );
}

function globalErrorHandler() {
  window.addEventListener('error', errorHandler);
}

export {
  globalErrorHandler as default,
  errorHandler,
};
