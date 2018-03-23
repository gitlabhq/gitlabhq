import { computeDiff } from './diff';

self.addEventListener('message', e => {
  const data = e.data;

  self.postMessage({
    key: data.key,
    changes: computeDiff(data.originalContent, data.newContent),
  });
});
