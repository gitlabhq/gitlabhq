/* eslint-disable max-classes-per-file, no-underscore-dangle */
const fs = require('fs');
const path = require('path');

const log = (msg, ...rest) => console.log(`IncrementalWebpackCompiler: ${msg}`, ...rest);

// If we force a recompile immediately, the page reload doesn't seem to work.
// Five seconds seem to work fine and the user can read the message
const TIMEOUT = 5000;

/* eslint-disable class-methods-use-this */
class NoopCompiler {
  constructor() {
    this.enabled = false;
  }

  filterEntryPoints(entryPoints) {
    return entryPoints;
  }

  logStatus() {}

  setupMiddleware() {}
}
/* eslint-enable class-methods-use-this */

class IncrementalWebpackCompiler {
  constructor(historyFilePath) {
    this.enabled = true;
    this.history = {};
    this.compiledEntryPoints = new Set([
      // Login page
      'pages.sessions.new',
      // Explore page
      'pages.root',
    ]);
    this.historyFilePath = historyFilePath;
    this._loadFromHistory();
  }

  filterEntryPoints(entrypoints) {
    return Object.fromEntries(
      Object.entries(entrypoints).map(([key, val]) => {
        if (this.compiledEntryPoints.has(key)) {
          return [key, val];
        }
        return [key, ['./webpack_non_compiled_placeholder.js']];
      }),
    );
  }

  logStatus(totalCount) {
    const current = this.compiledEntryPoints.size;
    log(`Currently compiling route entrypoints: ${current} of ${totalCount}`);
  }

  setupMiddleware(app, server) {
    app.use((req, res, next) => {
      const fileName = path.basename(req.url);

      /**
       * We are only interested in files that have a name like `pages.foo.bar.chunk.js`
       * because those are the ones corresponding to our entry points.
       *
       * This filters out hot update files that are for example named "pages.foo.bar.[hash].hot-update.js"
       */
      if (fileName.startsWith('pages.') && fileName.endsWith('.chunk.js')) {
        const chunk = fileName.replace(/\.chunk\.js$/, '');

        this._addToHistory(chunk);

        if (!this.compiledEntryPoints.has(chunk)) {
          log(`First time we are seeing ${chunk}. Adding to compilation.`);

          this.compiledEntryPoints.add(chunk);

          setTimeout(() => {
            server.middleware.invalidate(() => {
              if (server.sockets) {
                server.sockWrite(server.sockets, 'content-changed');
              }
            });
          }, TIMEOUT);
        }
      }

      next();
    });
  }

  // private methods

  _addToHistory(chunk) {
    if (!this.history[chunk]) {
      this.history[chunk] = { lastVisit: null, count: 0 };
    }
    this.history[chunk].lastVisit = Date.now();
    this.history[chunk].count += 1;

    try {
      fs.writeFileSync(this.historyFilePath, JSON.stringify(this.history), 'utf8');
    } catch (e) {
      log('Warning – Could not write to history', e.message);
    }
  }

  _loadFromHistory() {
    try {
      this.history = JSON.parse(fs.readFileSync(this.historyFilePath, 'utf8'));
      const entryPoints = Object.keys(this.history);
      log(`Successfully loaded history containing ${entryPoints.length} entry points`);
      /*
      TODO: Let's ask a few folks to give us their history file after a milestone of usage
            Then we can make smarter decisions on when to throw out rather than rendering everything
            Something like top 20/30/40 entries visited in the last 7/10/15 days might be sufficient
       */
      this.compiledEntryPoints = new Set([...this.compiledEntryPoints, ...entryPoints]);
    } catch (e) {
      log(`No history found...`);
    }
  }
}

module.exports = (enabled, historyFilePath) => {
  log(`Status – ${enabled ? 'enabled' : 'disabled'}`);

  if (enabled) {
    return new IncrementalWebpackCompiler(historyFilePath);
  }
  return new NoopCompiler();
};
