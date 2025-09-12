import { BOOTSTRAP_MIGRATIONS } from './bootstrap_tailwind_equivalents.mjs';

const BREAKPOINTS = ['sm', 'md', 'lg', 'xl'];

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
    return content.replace(
      /(?<!-|\w|!|:|gl-)(?<property>(col|order|offset|row-cols))-(?<width>(\d{1,2}|auto))(?!-|\w|!|:|gl-)/g,
      'gl-$<property>-$<width>',
    );
  },
  (content) => {
    return content.replace(
      /(?<!-|\w|!|:|gl-)(?<property>(col|order|offset|row-cols))-(?<breakpoint>sm|md|lg|xl)-(?<width>(\d{1,2}|auto))(?!-|\w|!|:|gl-)/g,
      'gl-$<property>-$<breakpoint>-$<width>',
    );
  },
  (content) => {
    let contentCopy = content;
    bootstrapMigrations.forEach(({ fromRegExp, to }) => {
      contentCopy = contentCopy.replace(fromRegExp, to);
    });
    return contentCopy;
  },
  (content) => {
    return content.replace(
      /(?<prefix>[^@])(?<breakpoint>sm|md|lg|xl):(?<important>!?)gl-/g,
      '$<prefix>@$<breakpoint>/panel:$<important>gl-',
    );
  },
];

const MEDIA_QUERIES_REPLACEMENTS = [
  (content) => {
    return content.replace(
      /@include media-breakpoint-up\((?<breakpoint>sm|md|lg|xl)\)/g,
      '@include gl-container-width-up($<breakpoint>, panel)',
    );
  },
  /**
   * Bootstrap's `media-breakpoint-down` mixin builds the media query
   * against the _next_ breakpoint, meaning that if you pass `sm` as the breakpoint
   * parameter, the resulting query targets breakpoints below `md`.
   */
  (content) => {
    const replacer = (_match, breakpoint) => {
      const breakpointIndex = BREAKPOINTS.findIndex((value) => value === breakpoint);
      const nextBreakpoint = BREAKPOINTS?.[breakpointIndex + 1];
      return `@include gl-container-width-down(${nextBreakpoint}, panel)`;
    };

    return content.replace(
      /@include media-breakpoint-down\((?<breakpoint>sm|md|lg|xl)\)/g,
      replacer,
    );
  },
  (content) => {
    return content.replace(
      /@include gl-media-breakpoint-up\((?<breakpoint>sm|md|lg|xl)\)/g,
      '@include gl-container-width-up($<breakpoint>, panel)',
    );
  },
  (content) => {
    return content.replace(
      /@include gl-media-breakpoint-down\((?<breakpoint>sm|md|lg|xl)\)/g,
      '@include gl-container-width-down($<breakpoint>, panel)',
    );
  },
  (content) => {
    return content.replace(
      /@media \(min-width: \$breakpoint-(?<breakpoint>sm|md|lg|xl)\)/g,
      '@include gl-container-width-up($<breakpoint>, panel)',
    );
  },
  (content) => {
    return content.replace(
      /@media \(max-width: \$breakpoint-(?<breakpoint>sm|md|lg|xl)\)/g,
      '@include gl-container-width-down($<breakpoint>, panel)',
    );
  },
  (content) => {
    return content.replace(
      /@media \(min-width: (?<width>\d+px)\)/g,
      '@container panel (width >= $<width>)',
    );
  },
  (content) => {
    return content.replace(
      /@media \(max-width: (?<width>\d+px)\)/g,
      '@container panel (width <= $<width>)',
    );
  },
  /**
   * This function doesn't do any replacements. It only serves as some sort of fallback
   * to warn about code that might need to be migrated but that this script doesn't know
   * how to handle.
   */
  (content) => {
    if (content.match(/@media \((min|max)-width/)) {
      console.warn(
        "Detected a media query that can't be migrated automatically. Please review the following code and proceed to the migration manually if needed.",
      );
      console.log(content);
    }
    return content;
  },
];

export function migrateCSSUtils(contents) {
  let contentsCopy = contents;
  UTILS_REPLACEMENTS.forEach((replacer) => {
    contentsCopy = replacer(contentsCopy);
  });
  return contentsCopy;
}

export function migrateMediaQueries(contents) {
  let contentsCopy = contents;
  MEDIA_QUERIES_REPLACEMENTS.forEach((replacer) => {
    contentsCopy = replacer(contentsCopy);
  });
  return contentsCopy;
}
