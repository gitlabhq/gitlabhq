const path = require('path');

module.exports = function workerLoader() {
  const basename = path.basename(this.resourcePath);
  const chunkName = basename.replace(/\.[^.]+$/, '');

  return `export default function WorkerFactory(options) {
  return new Worker(
    /* webpackChunkName: ${JSON.stringify(chunkName)} */
    new URL('./${basename}?worker_chunk', import.meta.url),
    { type: 'module', name: options && options.name },
  );
}
`;
};
