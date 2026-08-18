#!/usr/bin/env node

/**
 * Codemod: migrate app-bootstrap `new Vue(...)` roots to `initVueApp(...)`.
 *
 * Rewrites the mechanical bootstrap shape
 *
 *   new Vue({ el, name, provide, store, router, apolloProvider, pinia,
 *             render(h) { return h(App, { props }); } })
 *
 * to the dual-runtime helper
 *
 *   initVueApp({ el, name, provide, store, router, apolloProvider, pinia,
 *                component: App, props })
 *
 * which is exactly the same `new Vue` call on Vue 2 (production unchanged)
 * and a `createApp`-based mount with identical DOM semantics on Vue 3 (see
 * app/assets/javascripts/lib/utils/vue3compat/init_vue_app.js).
 *
 * Detection and the fix itself are owned by the `local-rules/vue3-init-vue-app`
 * ESLint rule (tooling/eslint-config/eslint-local-rules/vue3_init_vue_app.mjs);
 * this script drives that rule's autofix in batch, then runs the full repo
 * ESLint config with `--fix` over the touched files (import ordering, unused
 * `eslint-disable no-new` directives) and formats them with Prettier.
 * Bootstrap roots the rule cannot convert mechanically (event buses,
 * `$mount()` chains, template/components roots, renders with children or
 * Vue 2 data objects, `data`/lifecycle options) are left untouched and
 * printed as residual sites for the manual waves.
 *
 * Bootstrap census (2026-07-22, AST census of app/assets/javascripts +
 * ee/app/assets/javascripts): 642 `new Vue(` sites in 556 files, of which
 * 468 (72.9%) match the mechanical shape above; the residual splits into
 * 118 sites with options outside the helper surface and 56 sites with
 * non-trivial render bodies. Module-scope `Vue.use(...)`: 395 sites
 * (VueApollo 185, GlToast 62, VueRouter 54, Vuex 47, Translate 40, other 7),
 * to be folded into per-app `plugins: [...]` in later waves.
 *
 * Usage:
 *   # Dry run: list fixable and residual sites without touching files
 *   node scripts/frontend/codemods/vue3_init_vue_app.mjs --list [paths...]
 *
 *   # Apply fixes (defaults to app/assets/javascripts and
 *   # ee/app/assets/javascripts; pass directories or globs to run a wave)
 *   node scripts/frontend/codemods/vue3_init_vue_app.mjs [paths...]
 */

import path from 'node:path';
import fs from 'node:fs';
import { ESLint } from 'eslint';
import { program } from 'commander';
import * as prettier from 'prettier';
import eslintConfig from '../../../eslint.config.mjs';

const RULE = 'local-rules/vue3-init-vue-app';
const ROOT_PATH = path.resolve(import.meta.dirname, '../../../');
const DEFAULT_PATHS = ['./app/assets/javascripts/**/*.js', './ee/app/assets/javascripts/**/*.js'];

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
    .description('Rewrites mechanical `new Vue(...)` bootstrap roots to initVueApp(...).')
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
    // inserted helper import and removes eslint-disable directives (e.g.
    // `no-new`) that the conversion made unused.
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
