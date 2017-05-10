function globalErrorHandler() {
  // eslint-disable-next-line no-console
  window.addEventListener('error', console.log);
}

export default globalErrorHandler;
