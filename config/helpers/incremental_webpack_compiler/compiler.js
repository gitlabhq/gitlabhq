/* eslint-disable max-classes-per-file */

const path = require('path');
const { History, HistoryWithTTL } = require('./history');
const log = require('./log');

const onRequestEntryPoint = (callback) => {
  return (req, res, next) => {
    const fileName = path.basename(req.url);

    /**
     * We are only interested in files that have a name like `pages.foo.bar.chunk.js`
     * because those are the ones corresponding to our entry points.
     *
     * This filters out hot update files that are for example named "pages.foo.bar.[hash].hot-update.js"
     */
    if (fileName.startsWith('pages.') && fileName.endsWith('.chunk.js')) {
      const entryPoint = fileName.replace(/\.chunk\.js$/, '');
      callback(entryPoint);
    }

    next();
  };
};

/**
 * The NoopCompiler does nothing, following the null object pattern.
 */
class NoopCompiler {
  constructor() {
    this.enabled = false;
  }

  // eslint-disable-next-line class-methods-use-this
  filterEntryPoints(entryPoints) {
    return entryPoints;
  }

  // eslint-disable-next-line class-methods-use-this
  logStatus() {}

  // eslint-disable-next-line class-methods-use-this
  createMiddleware() {
    return null;
  }
}

/**
 * The HistoryOnlyCompiler only records which entry points have been requested.
 * This is so that if the user disables incremental compilation, history is
 * still recorded. If they later enable incremental compilation, that history
 * can be used.
 */
class HistoryOnlyCompiler extends NoopCompiler {
  constructor(historyFilePath) {
    super();
    this.history = new History(historyFilePath);
  }

  createMiddleware() {
    return onRequestEntryPoint((entryPoint) => {
      this.history.onRequestEntryPoint(entryPoint);
    });
  }
}

// If we force a recompile immediately, the page reload doesn't seem to work.
// Five seconds seem to work fine and the user can read the message
const TIMEOUT = 5000;

/**
 * The IncrementalWebpackCompiler tracks which entry points have been
 * requested, and only compiles entry points visited within the last `ttl`
 * days.
 */
class IncrementalWebpackCompiler {
  constructor(historyFilePath, ttl) {
    this.enabled = true;
    this.history = new HistoryWithTTL(historyFilePath, ttl);
  }

  filterEntryPoints(entrypoints) {
    return Object.fromEntries(
      Object.entries(entrypoints).map(([entryPoint, paths]) => {
        if (this.history.isRecentlyVisited(entryPoint)) {
          return [entryPoint, paths];
        }
        return [entryPoint, ['./webpack_non_compiled_placeholder.js']];
      }),
    );
  }

  logStatus(totalCount) {
    log(`Currently compiling route entrypoints: ${this.history.size} of ${totalCount}`);
  }

  createMiddleware(devServer) {
    return onRequestEntryPoint((entryPoint) => {
      const wasVisitedRecently = this.history.onRequestEntryPoint(entryPoint);
      if (!wasVisitedRecently) {
        log(`Have not visited ${entryPoint} recently. Adding to compilation.`);

        setTimeout(() => {
          devServer.invalidate(() => {
            if (Array.isArray(devServer.webSocketServer && devServer.webSocketServer.clients)) {
              devServer.sendMessage(devServer.webSocketServer.clients, 'static-changed');
            }
          });
        }, TIMEOUT);
      }
    });
  }
}

module.exports = {
  NoopCompiler,
  HistoryOnlyCompiler,
  IncrementalWebpackCompiler,
};
