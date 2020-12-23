/* useful for timing promises when jest fakeTimers are not reliable enough */
export default (timeout) =>
  new Promise((resolve) => {
    jest.useRealTimers();
    setTimeout(resolve, timeout);
    jest.useFakeTimers();
  });
