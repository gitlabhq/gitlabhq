/* eslint-disable import/extensions */
import {
  isFileExcluded,
  migrateCSSUtils,
  migrateMediaQueries,
} from '../../../../../scripts/frontend/lib/container_queries_migration.mjs';

jest.mock('node:fs', () => ({
  readFileSync: () => 'app/assets/javascripts/super_sidebar/\nfoo(bar|baz)\niam.regex',
}));

describe('isFileExcluded', () => {
  it.each(['app/assets/javascripts/super_sidebar/components/counter.vue', 'foobar'])(
    'returns true if the file "%s" matches an exclusion pattern',
    (file) => {
      expect(isFileExcluded(file)).toBe(true);
    },
  );

  it('converts lines to regexes', () => {
    expect(isFileExcluded('iamaregex')).toBe(true);
    expect(isFileExcluded('iam.regex')).toBe(true);
    expect(isFileExcluded('iam_regex')).toBe(true);
  });

  it('returns false if the file does not match any exclusion pattern', () => {
    expect(isFileExcluded('migrate_me')).toBe(false);
  });
});

describe('migrateCSSUtils', () => {
  const file = 'file.scss';

  it('replaces Bootstrap responsive column utils with their container queries equivalent', () => {
    const input = 'gl-col-12 gl-col-sm-9 gl-col-md-6 gl-col-lg-3 gl-col-xl-2';
    const output = 'gl-col-12 gl-col-sm-9 gl-col-md-6 gl-col-lg-3 gl-col-xl-2';

    expect(migrateCSSUtils(file, input)).toBe(output);
  });

  it.each`
    input                 | output
    ${'!gl-border-0'}     | ${'!gl-border-0'}
    ${'gl-order-1'}       | ${'gl-order-1'}
    ${'gl-order-md-1'}    | ${'gl-order-md-1'}
    ${'gl-col-lg-auto'}   | ${'gl-col-lg-auto'}
    ${'gl-row-cols-2'}    | ${'gl-row-cols-2'}
    ${'gl-row-cols-md-0'} | ${'gl-row-cols-md-0'}
    ${'gl-offset-2'}      | ${'gl-offset-2'}
    ${'gl-offset-sm-2'}   | ${'gl-offset-sm-2'}
    ${'gl-no-gutters'}    | ${'gl-no-gutters'}
  `('replaces Bootstrap grid util $input with $output', ({ input, output }) => {
    expect(migrateCSSUtils(file, input)).toBe(output);
  });

  it('replaces Bootstrap utils with their Tailwind equivalent', () => {
    const input = 'visible @xl/panel:!gl-flex-nowrap';
    const output = 'visible @xl/panel:!gl-flex-nowrap';

    expect(migrateCSSUtils(file, input)).toBe(output);
  });

  it('replaces Tailwind media query utils with their container query equivalent', () => {
    const input = '<div class="@sm/panel:gl-max-w-6/12 @lg/panel:gl-hidden">';
    const output = '<div class="@sm/panel:gl-max-w-6/12 @lg/panel:gl-hidden">';

    expect(migrateCSSUtils(file, input)).toBe(output);
  });

  it('replaces Tailwind media query utils with important modifier', () => {
    const input =
      '<div class="@sm/panel:!gl-flex-row @md/panel:!gl-items-center @lg/panel:gl-hidden">';
    const output =
      '<div class="@sm/panel:!gl-flex-row @md/panel:!gl-items-center @lg/panel:gl-hidden">';

    expect(migrateCSSUtils(file, input)).toBe(output);
  });

  // These aren't very relevant anymore as we have disabled the related migrations for now.
  it.each([
    '{ visible: true }',
    '<my-component :invisible="true">',
    '<div class="custom-rounded">',
  ])("does not replace strings that aren't CSS utils (eg '%s')", (input) => {
    expect(migrateCSSUtils(file, input)).toBe(input);
  });

  it.each`
    input            | output
    ${'gl-border-1'} | ${'gl-border-1'}
  `('does not replace existing valid Tailwind classes', ({ input, output }) => {
    expect(migrateCSSUtils(file, input)).toBe(output);
  });
});

describe('migrateMediaQueries', () => {
  const file = 'file.vue';

  it.each`
    input                                                     | output
    ${'@include media-breakpoint-up(md)'}                     | ${'@include gl-container-width-up(md, panel)'}
    ${'@include media-breakpoint-down(md)'}                   | ${'@include gl-container-width-down(lg, panel)'}
    ${'@include gl-media-breakpoint-up(md)'}                  | ${'@include gl-container-width-up(md, panel)'}
    ${'@include gl-media-breakpoint-down(md)'}                | ${'@include gl-container-width-down(md, panel)'}
    ${'@media (min-width: $breakpoint-md)'}                   | ${'@include gl-container-width-up(md, panel)'}
    ${'@media(min-width: $breakpoint-md)'}                    | ${'@include gl-container-width-up(md, panel)'}
    ${'@media (min-width: map.get($grid-breakpoints, md))'}   | ${'@include gl-container-width-up(md, panel)'}
    ${'@media (min-width: map.get($grid-breakpoints, md)-1)'} | ${'@include gl-container-width-up(md, panel)'}
    ${'@media(min-width: map.get($grid-breakpoints, md)-1)'}  | ${'@include gl-container-width-up(md, panel)'}
    ${'@media (max-width: $breakpoint-md)'}                   | ${'@include gl-container-width-down(md, panel)'}
    ${'@media (max-width: map.get($grid-breakpoints, md))'}   | ${'@include gl-container-width-down(md, panel)'}
    ${'@media (max-width: map.get($grid-breakpoints, md)-1)'} | ${'@include gl-container-width-down(md, panel)'}
    ${'@media(max-width: map.get($grid-breakpoints, md)-1)'}  | ${'@include gl-container-width-down(md, panel)'}
  `('rewrites $input to $output', ({ input, output }) => {
    expect(migrateMediaQueries(file, input)).toBe(output);
  });

  it.each`
    input                                              | query
    ${'@media (min-width: 420px) { \n somerule; \n }'} | ${'@media (min-width: 420px) { '}
    ${'@media (max-width: 100px) { \n somerule; \n }'} | ${'@media (max-width: 100px) { '}
  `('does not migrate and shows warning with query "$query"', ({ input, query }) => {
    const warn = jest.spyOn(console, 'warn').mockImplementation(() => {});

    expect(migrateMediaQueries(file, input)).toBe(input);

    expect(warn).toHaveBeenCalledWith(
      expect.stringContaining(
        "`file.vue`: contains media queries that can't be migrated automatically...",
      ),
    );
    expect(warn).toHaveBeenCalledWith(
      expect.stringContaining(`\`file.vue\`:   query #0: \`${query}\``),
    );
  });
});
