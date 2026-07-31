#!/usr/bin/env node

/**
 * Codemod: rewrite `$scopedSlots` usage in .vue files to the dual-runtime
 * `glSlots()` method.
 *
 *   v-if="$scopedSlots.foo"           -> v-if="glSlots().foo"
 *   this.$scopedSlots['foo']?.()      -> this.glSlots()['foo']?.()
 *   v-for="(_, name) in $scopedSlots" -> v-for="(_, name) in glSlots()"
 *
 * `glSlots()` (app/assets/javascripts/lib/utils/vue3compat/gl_slots_mixin.js)
 * returns `$scopedSlots` on Vue 2 — production behavior is unchanged — and
 * `$slots` on Vue 3, where the two maps are equivalent, so the component
 * stops firing the INSTANCE_SCOPED_SLOTS deprecation on the compat lane.
 * The Vue 2 `$slots` is not a direct substitute because it misses slots
 * passed with slot props.
 *
 * The first fixed site per file also injects the `glSlotsMixin` import and
 * registers it in the component's `mixins` array.
 *
 * Detection and the fix itself are owned by the `local-rules/vue3-gl-slots`
 * ESLint rule (tooling/eslint-config/eslint-local-rules/vue3_gl_slots.mjs);
 * this script drives that rule's autofix in batch, then runs the full repo
 * ESLint config with `--fix` over the touched files (import ordering) and
 * formats them with Prettier. Files whose default export the rule cannot
 * extend mechanically, and usages outside the default export, are left
 * untouched and printed as residual sites.
 *
 * Usage:
 *   # Dry run: list fixable and residual sites without touching files
 *   node scripts/frontend/codemods/vue3_gl_slots.mjs --list [paths...]
 *
 *   # Apply fixes (defaults to app/assets/javascripts and
 *   # ee/app/assets/javascripts; pass directories or globs to run a wave)
 *   node scripts/frontend/codemods/vue3_gl_slots.mjs [paths...]
 */

import path from 'node:path';
import fs from 'node:fs';
import { ESLint } from 'eslint';
import { program } from 'commander';
import * as prettier from 'prettier';
import eslintConfig from '../../../eslint.config.mjs';

const RULE = 'local-rules/vue3-gl-slots';
const ROOT_PATH = path.resolve(import.meta.dirname, '../../../');
const DEFAULT_PATHS = ['./app/assets/javascripts/**/*.vue', './ee/app/assets/javascripts/**/*.vue'];

/**
 * Strips the repo ESLint config down to the codemod rule only. With every
 * other rule stripped, all existing eslint-disable comments would be
 * reported as unused and *removed* by the fix pass, so unused directive
 * reporting must stay off.
 */
function getOverrideConfig() {
  return eslintConfig.map((config) => {
    // Keep global-ignore objects untouched: adding any other key would turn
    // them into scoped configs and drop the global ignores.
    if (config.ignores && !config.files && !config.rules) {
      return config;
    }
    const linterOptions = { ...config.linterOptions, reportUnusedDisableDirectives: 'off' };
    return { ...config, linterOptions, rules: { [RULE]: 'error' } };
  });
}

function formatMessage(filePath, message) {
  return `${path.relative(ROOT_PATH, filePath)}:${message.line}:${message.column}`;
}

async function main() {
  program
    .description('Rewrites $scopedSlots usage to the dual-runtime glSlots() mixin method.')
    .option('--list', 'Dry run: print fixable and residual sites without modifying files.')
    .argument('[paths...]', 'Files, directories or globs to transform.')
    .parse(process.argv);

  const options = program.opts();
  const lintPaths = program.args.length > 0 ? program.args : DEFAULT_PATHS;

  const eslint = new ESLint({
    overrideConfigFile: true,
    overrideConfig: getOverrideConfig(),
    fix: !options.list,
    cache: false,
  });

  console.log(`Linting ${lintPaths.join(', ')} with ${RULE}...`);
  const results = await eslint.lintFiles(lintPaths);

  const fixable = [];
  const residual = [];
  const touchedFiles = [];

  results.forEach((result) => {
    if (result.output !== undefined) {
      touchedFiles.push(result.filePath);
      fs.writeFileSync(result.filePath, result.output);
    }

    result.messages.forEach((message) => {
      if (message.ruleId !== RULE) {
        return;
      }
      // In fix mode, `messages` only contains what could not be fixed. In
      // list mode, fixable messages carry a `fix` property.
      if (options.list && message.fix) {
        fixable.push(formatMessage(result.filePath, message));
      } else {
        residual.push(formatMessage(result.filePath, message));
      }
    });
  });

  if (options.list) {
    if (fixable.length > 0) {
      console.log(`\n${fixable.length} fixable site(s):`);
      fixable.forEach((site) => console.log(`  ${site}`));
    }
  } else if (touchedFiles.length > 0) {
    // Second pass with the real repo config: fixes the import order of the
    // inserted mixin import and removes eslint-disable directives that the
    // conversion made unused.
    console.log(`Running the repo ESLint config with --fix over ${touchedFiles.length} file(s)...`);
    const fullEslint = new ESLint({ fix: true, cache: false });
    const fullResults = await fullEslint.lintFiles(touchedFiles);
    await ESLint.outputFixes(fullResults);

    await Promise.all(
      touchedFiles.map(async (filePath) => {
        const prettierConfig = await prettier.resolveConfig(filePath);
        const formatted = await prettier.format(fs.readFileSync(filePath, 'utf8'), {
          ...prettierConfig,
          filepath: filePath,
        });
        fs.writeFileSync(filePath, formatted);
      }),
    );
    console.log(`\nFixed and formatted ${touchedFiles.length} file(s).`);
  } else {
    console.log('\nNo fixable sites found.');
  }

  if (residual.length > 0) {
    console.log(`\n${residual.length} residual site(s) this codemod will NOT touch:`);
    residual.forEach((site) => console.log(`  ${site}`));
  } else {
    console.log('\nNo residual sites.');
  }
}

main();
