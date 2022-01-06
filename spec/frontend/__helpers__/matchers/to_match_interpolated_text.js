export const toMatchInterpolatedText = (received, match) => {
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
        \n\n
        Expected: ${this.utils.printExpected(clearReceived)}
        To not equal: ${this.utils.printReceived(clearMatch)}
        `
    : () =>
        `
      \n\n
      Expected: ${this.utils.printExpected(clearReceived)}
      To equal: ${this.utils.printReceived(clearMatch)}
      `;

  return { actual: received, message, pass };
};
