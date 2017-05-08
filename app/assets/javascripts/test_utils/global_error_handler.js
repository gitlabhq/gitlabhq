function globalErrorHandler() {
  // eslint-disable-next-line no-console
  window.addEventListener('error', console.error);
}

export default globalErrorHandler;
