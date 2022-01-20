import { diff } from 'jest-diff';
import { isObject, mapValues, isEqual } from 'lodash';

export const toHaveTrackingAttributes = (actual, obj) => {
  if (!(actual instanceof Element)) {
    return { actual, message: () => 'The received value must be an Element.', pass: false };
  }

  if (!isObject(obj)) {
    return {
      message: () => `The matching object must be an object. Found ${obj}.`,
      pass: false,
    };
  }

  const actualAttributes = mapValues(obj, (val, key) => actual.getAttribute(`data-track-${key}`));

  const matcherPass = isEqual(actualAttributes, obj);

  const failMessage = () => {
    // We can match, but still fail because we're in a `expect...not.` context
    if (matcherPass) {
      return `Expected the element's tracking attributes not to match. Found that they matched ${JSON.stringify(
        obj,
      )}.`;
    }

    const objDiff = diff(actualAttributes, obj);
    return `Expected the element's tracking attributes to match the given object. Diff:
${objDiff}
`;
  };

  return { actual, message: failMessage, pass: matcherPass };
};
