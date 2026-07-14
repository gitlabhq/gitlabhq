/**
 * Reveals the violations a single ESLint rule still has in files that are
 * grandfathered via `.eslint_todo`. Intended for a non-blocking CI job that
 * surfaces outstanding tech debt for one rule without affecting the main
 * (blocking) `eslint` job.
 *
 * Usage:
 *   node scripts/frontend/reveal_eslint_todo_rule.mjs local-rules/no-apollo-mock
 *
 * Exits non-zero when violations remain, so the job is visible (pair with
 * `allow_failure: true` in CI to keep it non-blocking).
 */
import path from 'node:path';
import { ESLint } from 'eslint';

const ROOT_PATH = path.resolve(import.meta.dirname, '../../');

const rule = process.argv[2];
if (!rule) {
  console.error('Usage: reveal_eslint_todo_rule.mjs <rule-id>');
  process.exit(2);
}

// Disable the `.eslint_todo` suppressions so the rule fires on the
// grandfathered files. The flat config reads this at import time, so it must
// be set before ESLint loads the configuration.
process.env.REVEAL_ESLINT_TODO = 'true';

// The generator names todo files after the rule id with `/` replaced by `-`.
const todoModulePath = path.join(ROOT_PATH, '.eslint_todo', `${rule.replace(/\//g, '-')}.mjs`);

let todo;
try {
  // The todo module path is derived from a trusted CLI argument in this
  // dev-only tooling script, so the dynamic import is intentional and safe.
  // eslint-disable-next-line import/no-dynamic-require, no-unsanitized/method
  ({ default: todo } = await import(todoModulePath));
} catch {
  console.error(`No .eslint_todo list found for "${rule}" (expected ${todoModulePath}).`);
  process.exit(2);
}

const files = todo.files.map((file) => path.join(ROOT_PATH, file));
const eslint = new ESLint({ cwd: ROOT_PATH });
const results = await eslint.lintFiles(files);

let count = 0;
for (const result of results) {
  for (const message of result.messages) {
    if (message.ruleId !== rule) continue;
    count += 1;
    console.log(
      `${path.relative(ROOT_PATH, result.filePath)}:${message.line}:${message.column}  ${message.message}`,
    );
  }
}

console.log(`\n${count} \`${rule}\` violation(s) remaining in grandfathered files.`);
process.exit(count > 0 ? 1 : 0);
