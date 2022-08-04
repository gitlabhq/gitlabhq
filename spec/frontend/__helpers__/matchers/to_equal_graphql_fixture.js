import { isEqual } from 'lodash';
import { stripTypenames } from 'helpers/graphql_helpers';

export function toEqualGraphqlFixture(received, match) {
  let clearReceived;
  let clearMatch;

  try {
    clearReceived = JSON.parse(JSON.stringify(received));
    clearMatch = stripTypenames(match);
  } catch (e) {
    return { message: () => 'The comparator value is not an object', pass: false };
  }
  const pass = isEqual(clearReceived, clearMatch);
  // console.log(this.utils);
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
