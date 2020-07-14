import { differenceBy } from 'lodash';

const KEY_TO_FILTER_BY = 'fingerprint';

// eslint-disable-next-line no-restricted-globals
self.addEventListener('message', e => {
  const { data } = e;

  if (data === undefined) {
    return null;
  }

  const { headIssues, baseIssues } = data;

  if (!headIssues || !baseIssues) {
    // eslint-disable-next-line no-restricted-globals
    return self.postMessage({});
  }

  // eslint-disable-next-line no-restricted-globals
  self.postMessage({
    newIssues: differenceBy(headIssues, baseIssues, KEY_TO_FILTER_BY),
    resolvedIssues: differenceBy(baseIssues, headIssues, KEY_TO_FILTER_BY),
  });

  // eslint-disable-next-line no-restricted-globals
  return self.close();
});
