const { NoopCompiler, HistoryOnlyCompiler, IncrementalWebpackCompiler } = require('./compiler');
const log = require('./log');

// eslint-disable-next-line max-params
module.exports = (recordHistory, enabled, historyFilePath, ttl) => {
  if (!recordHistory) {
    log(`Status – disabled`);
    return new NoopCompiler();
  }

  if (enabled) {
    log(`Status – enabled, ttl=${ttl}`);
    return new IncrementalWebpackCompiler(historyFilePath, ttl);
  }

  log(`Status – history-only`);
  return new HistoryOnlyCompiler(historyFilePath);
};
