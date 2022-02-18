// Custom matchers are object methods and should be traditional functions to be able to access `utils` on `this`
export function toMatchInterpolatedText(received, match) {
  let clearReceived;
  let clearMatch;

  try {
    clearReceived = received.replace(/\s\s+/gm, ' ').replace(/\s\./gm, '.').trim();
  } catch (e) {
    return { actual: received, message: 'The received value is not a string', pass: false };
  }
  try {
    clearMatch = match.replace(/%{\w+}/gm, '').trim();
  } catch (e) {
    return { message: 'The comparator value is not a string', pass: false };
  }
  const pass = clearReceived === clearMatch;
  const message = pass
    ? () => `
        Expected to not be: ${this.utils.printExpected(clearMatch)}
        Received:           ${this.utils.printReceived(clearReceived)}
        `
    : () =>
        `
      Expected to be: ${this.utils.printExpected(clearMatch)}
      Received:       ${this.utils.printReceived(clearReceived)}
      `;

  return { actual: received, message, pass };
}
