// eslint-disable-next-line max-params
export function toMatchExpectedForMarkdown(
  received,
  deserializationTarget,
  name,
  markdown,
  errMsg,
  expected,
) {
  const options = {
    comment: `Markdown deserialization to ${deserializationTarget}`,
    isNot: this.isNot,
    promise: this.promise,
  };

  const EXPECTED_LABEL = 'Expected';
  const RECEIVED_LABEL = 'Received';
  const isExpand = (expand) => expand !== false;
  const forMarkdownName = `for Markdown example '${name}':\n${markdown}`;
  const matcherName = `toMatchExpected${
    deserializationTarget === 'HTML' ? 'Html' : 'Json'
  }ForMarkdown`;

  let pass;

  // If both expected and received are deserialization errors, force pass = true,
  // because the actual error messages can vary across environments and cause
  // false failures (e.g. due to jest '--coverage' being passed in CI).
  const errMsgRegExp = new RegExp(errMsg);
  const errMsgRegExp2 = new RegExp(errMsg);

  if (errMsgRegExp.test(expected) && errMsgRegExp2.test(received)) {
    pass = true;
  } else {
    pass = received === expected;
  }

  const message = pass
    ? () =>
        // eslint-disable-next-line prefer-template
        this.utils.matcherHint(matcherName, undefined, undefined, options) +
        '\n\n' +
        `Expected HTML to NOT match:\n${expected}\n\n${forMarkdownName}`
    : () => {
        return (
          // eslint-disable-next-line prefer-template
          this.utils.matcherHint(matcherName, undefined, undefined, options) +
          '\n\n' +
          this.utils.printDiffOrStringify(
            expected,
            received,
            EXPECTED_LABEL,
            RECEIVED_LABEL,
            isExpand(this.expand),
          ) +
          `\n\n${forMarkdownName}`
        );
      };

  return { actual: received, expected, message, name: matcherName, pass };
}
