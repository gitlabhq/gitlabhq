import { computeDiff } from './diff';

// eslint-disable-next-line no-restricted-globals
self.addEventListener('message', (e) => {
  const { data } = e;

  // eslint-disable-next-line no-restricted-globals
  self.postMessage({
    path: data.path,
    changes: computeDiff(data.originalContent, data.newContent),
  });
});
