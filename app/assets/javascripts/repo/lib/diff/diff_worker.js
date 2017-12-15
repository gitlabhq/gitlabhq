import { computeDiff } from './diff';

// eslint-disable-next-line prefer-arrow-callback
self.addEventListener('message', function diffWorker(e) {
  const data = e.data;

  self.postMessage({
    path: data.path,
    changes: computeDiff(data.originalContent, data.newContent),
  });
});
