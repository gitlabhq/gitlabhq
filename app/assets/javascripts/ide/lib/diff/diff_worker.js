import { computeDiff } from './diff';

self.addEventListener('message', (e) => {
  const data = e.data;

  self.postMessage({
    path: data.path,
    changes: computeDiff(data.originalContent, data.newContent),
  });
});
