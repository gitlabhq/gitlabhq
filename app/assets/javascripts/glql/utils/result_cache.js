// Filter and date range changes add entries that no reload forgets. Past the cap, the least
// recently used entry goes, so the panels still on screen keep theirs.
const MAX_ENTRIES = 200;

// Bounds how old the numbers on a dashboard left open can get: long enough for the tab switches
// and filter round trips the cache is for, short enough that they stay current.
const MAX_AGE_MS = 5 * 60 * 1000;

// Results by compiled query and variables. Each entry remembers the tags of the requests that
// produced, read or wait for it, so a panel's reload can drop its own results, comparison and
// pages included.
export default class ResultCache {
  #entries = new Map();

  // The reader's tag is recorded too: a reload of that source has to drop the result as well.
  read(key, tag) {
    const entry = this.#entries.get(key);
    if (!entry) return undefined;

    if (entry.expiresAt <= Date.now()) {
      this.#entries.delete(key);
      return undefined;
    }

    if (tag !== undefined) entry.tags.add(tag);
    // A Map iterates in insertion order, so re-inserting moves the entry to the back of the line.
    this.#entries.delete(key);
    this.#entries.set(key, entry);

    return entry.data;
  }

  set(key, data, tag) {
    const entry = this.#entries.get(key) ?? { tags: new Set() };

    entry.data = data;
    entry.expiresAt = Date.now() + MAX_AGE_MS;
    if (tag !== undefined) entry.tags.add(tag);
    this.#store(key, entry);
  }

  // Records that a request tagged `tag` is waiting for `key` before any request for it has
  // started, so forgetting the tag also drops the request it would have joined. Reads as a miss
  // until data arrives.
  claim(key, tag) {
    if (tag === undefined) return;

    const entry = this.#entries.get(key) ?? { tags: new Set() };

    entry.tags.add(tag);
    this.#store(key, entry);
  }

  // Only while `data` is still the entry's: a later request may have replaced it.
  delete(key, data) {
    if (this.#entries.get(key)?.data === data) this.#entries.delete(key);
  }

  forget(tag) {
    this.#entries.forEach((entry, key) => {
      if (entry.tags.has(tag)) this.#entries.delete(key);
    });
  }

  get size() {
    return this.#entries.size;
  }

  #store(key, entry) {
    this.#entries.set(key, entry);
    if (this.#entries.size > MAX_ENTRIES) this.#entries.delete(this.#entries.keys().next().value);
  }
}
