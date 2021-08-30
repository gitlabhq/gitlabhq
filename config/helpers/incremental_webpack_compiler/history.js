/* eslint-disable max-classes-per-file, no-underscore-dangle */

const fs = require('fs');
const log = require('./log');

const ESSENTIAL_ENTRY_POINTS = [
  // Login page
  'pages.sessions.new',
  // Explore page
  'pages.root',
];

// TODO: Find a way to keep this list up-to-date/relevant.
const COMMON_ENTRY_POINTS = [
  ...ESSENTIAL_ENTRY_POINTS,
  'pages.admin',
  'pages.admin.dashboard',
  'pages.dashboard.groups.index',
  'pages.dashboard.projects.index',
  'pages.groups.new',
  'pages.groups.show',
  'pages.profiles.preferences.show',
  'pages.projects.commit.show',
  'pages.projects.edit',
  'pages.projects.issues.index',
  'pages.projects.issues.new',
  'pages.projects.issues.show',
  'pages.projects.jobs.show',
  'pages.projects.merge_requests.index',
  'pages.projects.merge_requests.show',
  'pages.projects.milestones.index',
  'pages.projects.new',
  'pages.projects.pipelines.index',
  'pages.projects.pipelines.show',
  'pages.projects.settings.ci_cd.show',
  'pages.projects.settings.repository.show',
  'pages.projects.show',
  'pages.users',
];

/**
 * The History class is responsible for tracking which entry points have been
 * requested, and persisting/loading the history to/from disk.
 */
class History {
  constructor(historyFilePath) {
    this._historyFilePath = historyFilePath;
    this._history = {};

    this._loadHistoryFile();
  }

  onRequestEntryPoint(entryPoint) {
    const wasVisitedRecently = this.isRecentlyVisited(entryPoint);

    this._addEntryPoint(entryPoint);

    this._writeHistoryFile();

    return wasVisitedRecently;
  }

  // eslint-disable-next-line class-methods-use-this
  isRecentlyVisited() {
    return true;
  }

  // eslint-disable-next-line class-methods-use-this
  get size() {
    return 0;
  }

  // Private methods

  _addEntryPoint(entryPoint) {
    if (!this._history[entryPoint]) {
      this._history[entryPoint] = { lastVisit: null, count: 0 };
    }

    this._history[entryPoint].lastVisit = Date.now();
    this._history[entryPoint].count += 1;
  }

  _writeHistoryFile() {
    try {
      fs.writeFileSync(this._historyFilePath, JSON.stringify(this._history), 'utf8');
    } catch (error) {
      log('Warning – Could not write to history', error.message);
    }
  }

  _loadHistoryFile() {
    try {
      fs.accessSync(this._historyFilePath);
    } catch (e) {
      // History file doesn't exist; attempt to seed it, and return early
      this._seedHistory();
      return;
    }

    // History file already exists; attempt to load its contents into memory
    try {
      this._history = JSON.parse(fs.readFileSync(this._historyFilePath, 'utf8'));
      const historySize = Object.keys(this._history).length;
      log(`Successfully loaded history containing ${historySize} entry points`);
    } catch (error) {
      log('Could not load history', error.message);
    }
  }

  /**
   * Seeds a reasonable set of approximately the most common entry points to
   * seed the history. This helps to avoid fresh GDK installs showing the
   * compiling overlay too often.
   */
  _seedHistory() {
    log('Seeding history...');
    COMMON_ENTRY_POINTS.forEach((entryPoint) => this._addEntryPoint(entryPoint));
    this._writeHistoryFile();
  }
}

const MS_PER_DAY = 1000 * 60 * 60 * 24;

/**
 * The HistoryWithTTL class adds LRU-like behaviour onto the base History
 * behaviour. Entry points visited within the last `ttl` days are considered
 * "recent", and therefore should be eagerly compiled.
 */
class HistoryWithTTL extends History {
  constructor(historyFilePath, ttl) {
    super(historyFilePath);
    this._ttl = ttl;
    this._calculateRecentEntryPoints();
  }

  onRequestEntryPoint(entryPoint) {
    const wasVisitedRecently = super.onRequestEntryPoint(entryPoint);

    this._calculateRecentEntryPoints();

    return wasVisitedRecently;
  }

  isRecentlyVisited(entryPoint) {
    return this._recentEntryPoints.has(entryPoint);
  }

  get size() {
    return this._recentEntryPoints.size;
  }

  // Private methods

  _calculateRecentEntryPoints() {
    const oldestVisitAllowed = Date.now() - MS_PER_DAY * this._ttl;

    const recentEntryPoints = Object.entries(this._history).reduce(
      (acc, [entryPoint, { lastVisit }]) => {
        if (lastVisit > oldestVisitAllowed) {
          acc.push(entryPoint);
        }

        return acc;
      },
      [],
    );

    this._recentEntryPoints = new Set([...ESSENTIAL_ENTRY_POINTS, ...recentEntryPoints]);
  }
}

module.exports = {
  History,
  HistoryWithTTL,
};
