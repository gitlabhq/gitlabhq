import { readFileSync } from 'node:fs';
import { memoize } from 'lodash-es';
import { BOOTSTRAP_MIGRATIONS } from './bootstrap_tailwind_equivalents.mjs';

const getExclusionPatterns = memoize(() => {
  const exclusions = readFileSync(
    'scripts/frontend/lib/container_queries_migration_exclusions.txt',
    'utf-8',
  );
  return exclusions
    .split('\n')
    .map((s) => s.split('#')[0])
    .filter(Boolean)
    .map((pattern) => new RegExp(pattern));
});

function addFromRegExps(rawMigrations) {
  const classChars = ['-', '\\w', '!', ':', 'gl-'].join('|');
  return rawMigrations.map((migration) => ({
    ...migration,
    fromRegExp: new RegExp(`(?<!${classChars})${migration.from}(?!${classChars})`, 'g'),
  }));
}

function sortMigrations(unsortedMigrations) {
  return (
    unsortedMigrations
      .slice()
      // Migrate "foobar" and "bar foo" before "foo" so we don't incorrectly
      // migrate "foo".
      .sort((a, b) => {
        if (a.from.length < b.from.length) return 1;
        if (a.from.length > b.from.length) return -1;
        return 0;
      })
  );
}

function filterOutNonStringValues(rawMigrations) {
  return Object.entries(rawMigrations)
    .filter(([, to]) => typeof to === 'string')
    .map(([from, to]) => ({ from, to }));
}

const bootstrapMigrations = sortMigrations(
  addFromRegExps(filterOutNonStringValues(BOOTSTRAP_MIGRATIONS)),
);

const UTILS_REPLACEMENTS = [
  (content) => {
    let contentCopy = content;
    bootstrapMigrations.forEach(({ fromRegExp, to }) => {
      contentCopy = contentCopy.replace(fromRegExp, to);
    });
    return contentCopy;
  },
];

export function isFileExcluded(file) {
  const exclusionPatterns = getExclusionPatterns();
  return exclusionPatterns.some((pattern) => file.match(pattern));
}

export function migrateCSSUtils(file, contents) {
  let contentsCopy = contents;
  UTILS_REPLACEMENTS.forEach((replacer) => {
    contentsCopy = replacer(contentsCopy);
  });
  return contentsCopy;
}
