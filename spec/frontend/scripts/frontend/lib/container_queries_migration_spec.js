/* eslint-disable import/extensions */
import {
  migrateCSSUtils,
  migrateMediaQueries,
} from '../../../../../scripts/frontend/lib/container_queries_migration.mjs';

describe('migrateCSSUtils', () => {
  it('replaces Bootstrap responsive column utils with their container queries equivalent', () => {
    const input = 'col-12 col-sm-9 col-md-6 col-lg-3 col-xl-2';
    const output = 'gl-col-12 gl-col-sm-9 gl-col-md-6 gl-col-lg-3 gl-col-xl-2';

    expect(migrateCSSUtils(input)).toBe(output);
  });

  it.each`
    input              | output
    ${'border-0'}      | ${'!gl-border-0'}
    ${'order-1'}       | ${'gl-order-1'}
    ${'order-md-1'}    | ${'gl-order-md-1'}
    ${'col-lg-auto'}   | ${'gl-col-lg-auto'}
    ${'row-cols-2'}    | ${'gl-row-cols-2'}
    ${'row-cols-md-0'} | ${'gl-row-cols-md-0'}
    ${'offset-2'}      | ${'gl-offset-2'}
    ${'offset-sm-2'}   | ${'gl-offset-sm-2'}
    ${'no-gutters'}    | ${'gl-no-gutters'}
  `('replaces Bootstrap grid util $input with $output', ({ input, output }) => {
    expect(migrateCSSUtils(input)).toBe(output);
  });

  it('replaces Bootstrap utils with their Tailwind equivalent', () => {
    const input = 'visible flex-xl-nowrap';
    const output = 'visible @xl/panel:!gl-flex-nowrap';

    expect(migrateCSSUtils(input)).toBe(output);
  });

  it('replaces Tailwind media query utils with their container query equivalent', () => {
    const input = '<div class="sm:gl-max-w-6/12 lg:gl-hidden">';
    const output = '<div class="@sm/panel:gl-max-w-6/12 @lg/panel:gl-hidden">';

    expect(migrateCSSUtils(input)).toBe(output);
  });

  it('replaces Tailwind media query utils with important modifier', () => {
    const input = '<div class="sm:!gl-flex-row md:!gl-items-center lg:gl-hidden">';
    const output =
      '<div class="@sm/panel:!gl-flex-row @md/panel:!gl-items-center @lg/panel:gl-hidden">';

    expect(migrateCSSUtils(input)).toBe(output);
  });

  // These aren't very relevant anymore as we have disabled the related migrations for now.
  it.each([
    '{ visible: true }',
    '<my-component :invisible="true">',
    '<div class="custom-rounded">',
  ])("does not replace strings that aren't CSS utils (eg '%s')", (input) => {
    expect(migrateCSSUtils(input)).toBe(input);
  });

  it.each`
    input            | output
    ${'gl-border-1'} | ${'gl-border-1'}
  `('does not replace existing valid Tailwind classes', ({ input, output }) => {
    expect(migrateCSSUtils(input)).toBe(output);
  });
});

describe('migrateMediaQueries', () => {
  it.each`
    input                                      | output
    ${'@include media-breakpoint-up(md)'}      | ${'@include gl-container-width-up(md, panel)'}
    ${'@include media-breakpoint-down(md)'}    | ${'@include gl-container-width-down(lg, panel)'}
    ${'@include gl-media-breakpoint-up(md)'}   | ${'@include gl-container-width-up(md, panel)'}
    ${'@include gl-media-breakpoint-down(md)'} | ${'@include gl-container-width-down(md, panel)'}
    ${'@media (min-width: $breakpoint-md)'}    | ${'@include gl-container-width-up(md, panel)'}
    ${'@media (max-width: $breakpoint-md)'}    | ${'@include gl-container-width-down(md, panel)'}
  `('rewrites $input to $output', ({ input, output }) => {
    expect(migrateMediaQueries(input)).toBe(output);
  });

  it.each`
    input                                                     | warning
    ${'@media (min-width: 420px) { \n somerule; \n }'}        | ${'@media (min-width: 420px) { '}
    ${'@media (max-width: 100px) { \n somerule; \n }'}        | ${'@media (max-width: 100px) { '}
    ${'@media (max-width: map.get($grid-breakpoints, lg)-1)'} | ${'@media (max-width: map.get($grid-breakpoints, lg)-1)'}
  `('does not migrate and shows warning: "$warning"', ({ input, warning }) => {
    const warn = jest.spyOn(console, 'warn').mockImplementation(() => {});

    expect(migrateMediaQueries(input)).toBe(input);

    expect(warn).toHaveBeenCalledWith(
      "Detected a media query that can't be migrated automatically. Please review the following code and proceed to the migration manually if needed.",
    );
    expect(warn).toHaveBeenCalledWith([warning]);
  });
});
