#!/usr/bin/env node

/**
 * Codemod: migrate jest specs off the VTU v1 "find upgrade".
 *
 * Rewrites string-selector finder calls whose result flows into
 * component-only wrapper APIs (`.vm`, `.props()`, `.setProps()`,
 * `.setData()`, `.emitted()`, `.destroy()`, `.unmount()`):
 *
 *   find -> findComponent
 *   findAll -> findAllComponents
 *   findByTestId -> findComponentByTestId
 *   findAllByTestId -> findAllComponentsByTestId
 *
 * Detection and the fix itself are owned by the
 * `local-rules/vue3-find-component-upgrade` ESLint rule
 * (tooling/eslint-config/eslint-local-rules/vue3_find_component_upgrade.mjs);
 * this script drives that rule's autofix in batch and formats touched files
 * with Prettier. Sites the rule reports without a fix (e.g. finders mixing
 * component-only APIs with setValue/setChecked/setSelected) are left
 * untouched and printed as residual sites for manual follow-up.
 *
 * Usage:
 *   # Dry run: list fixable and residual sites without touching files
 *   node scripts/frontend/codemods/vue3_find_component_upgrade.mjs --list [paths...]
 *
 *   # Apply fixes (defaults to spec/frontend and ee/spec/frontend)
 *   node scripts/frontend/codemods/vue3_find_component_upgrade.mjs [paths...]
 *
 * After applying to previously-exempted files, regenerate the todo list:
 *   node scripts/frontend/generate_eslint_todo_list.mjs local-rules/vue3-find-component-upgrade
 */

import path from 'node:path';
import fs from 'node:fs';
import { ESLint } from 'eslint';
import { program } from 'commander';
import * as prettier from 'prettier';
import eslintConfig from '../../../eslint.config.mjs';

const RULE = 'local-rules/vue3-find-component-upgrade';
const ROOT_PATH = path.resolve(import.meta.dirname, '../../../');
const DEFAULT_PATHS = ['./spec/frontend/**/*.js', './ee/spec/frontend/**/*.js'];

/**
 * Strips the repo ESLint config down to the codemod rule only. Configs that
 * turn the rule off (the generated `.eslint_todo` exemption list) are
 * bypassed so that exempted files still get fixed.
 */
function getOverrideConfig() {
  return eslintConfig.map((config) => {
    // Keep global-ignore objects untouched: adding any other key would turn
    // them into scoped configs and drop the global ignores.
    if (config.ignores && !config.files && !config.rules) {
      return config;
    }
    const ruleSeverity = config.rules?.[RULE];
    // With every other rule stripped, all existing eslint-disable comments
    // would be reported as unused and *removed* by the fix pass, so unused
    // directive reporting must stay off.
    const linterOptions = { ...config.linterOptions, reportUnusedDisableDirectives: 'off' };
    if (ruleSeverity && ruleSeverity !== 'off') {
      return { ...config, linterOptions, rules: { [RULE]: ruleSeverity } };
    }
    return { ...config, linterOptions, rules: {} };
  });
}

function formatMessage(filePath, message) {
  return `${path.relative(ROOT_PATH, filePath)}:${message.line}:${message.column}`;
}

async function main() {
  program
    .description('Rewrites string-selector find() calls used with component-only wrapper APIs.')
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
  let touchedFiles = 0;

  await Promise.all(
    results.map(async (result) => {
      if (result.output !== undefined) {
        touchedFiles += 1;
        const prettierConfig = await prettier.resolveConfig(result.filePath);
        const formatted = await prettier.format(result.output, {
          ...prettierConfig,
          filepath: result.filePath,
        });
        fs.writeFileSync(result.filePath, formatted);
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
    }),
  );

  if (options.list) {
    if (fixable.length > 0) {
      console.log(`\n${fixable.length} fixable site(s):`);
      fixable.forEach((site) => console.log(`  ${site}`));
    }
  } else {
    console.log(`\nFixed and formatted ${touchedFiles} file(s).`);
  }

  if (residual.length > 0) {
    console.log(`\n${residual.length} residual site(s) this codemod will NOT touch:`);
    residual.forEach((site) => console.log(`  ${site}`));
  } else {
    console.log('\nNo residual sites.');
  }
}

main();
