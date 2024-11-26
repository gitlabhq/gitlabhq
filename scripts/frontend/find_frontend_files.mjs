#!/usr/bin/env node
import { relative, resolve } from 'node:path';

import Runtime from 'jest-runtime';
import { readConfig } from 'jest-config';

import createJestConfig from '../../jest.config.base.js';

const ROOT = resolve(import.meta.dirname, '../../');

function resolveDependenciesRecursively(context, target, seen) {
  const dependencies = context.hasteFS.getDependencies(target);

  seen.add(target);
  if (!dependencies) {
    return [target];
  }

  return [
    target,
    ...dependencies.flatMap((file) => {
      const fileNormalized = file.replace(/\/+/g, '/');

      const resolved = relative(
        context.config.rootDir,
        context.resolver.resolveModule(target, fileNormalized),
      );

      if (resolved.startsWith('node_modules/')) {
        return [];
      }

      if (seen.has(resolved)) {
        return [];
      }

      return resolveDependenciesRecursively(context, resolved, seen);
    }),
  ];
}

async function getJestConfig(opts = {}) {
  return (
    await readConfig(
      {
        config: JSON.stringify(
          createJestConfig('spec/frontend', {
            roots: ['<rootDir>/spec/frontend/'],
            rootsEE: ['<rootDir>/ee/spec/frontend/'],
            rootsJH: ['<rootDir>/jh/spec/frontend/'],
            ...opts,
          }),
        ),
      },
      ROOT,
    )
  ).projectConfig;
}

async function resolveDependenciesWithJest(target, opts = {}) {
  const seen = new Set();
  const { isEE = false, isJH = false } = opts;
  const config = await getJestConfig({ isEE, isJH });
  const context = await Runtime.default.createContext(config, {
    maxWorkers: 1,
    console,
    watch: false,
  });
  return resolveDependenciesRecursively(context, target, seen);
}

/**
 * This script takes a frontend files as its only argument and walks the tree to find all files it
 * depends on, then prints all their paths to stdin, including the provided file.
 *
 * Usage:
 * scripts/frontend/find_frontend_files.mjs path/to/file.js
 *
 * This can be useful when migrating Tailwind utils in a given file and we'd like to migrate all
 * dependents at the same time. Eg:
 * scripts/frontend/find_frontend_files.mjs path/to/file.js | ./node_modules/@gitlab/ui/bin/migrate_custom_utils_to_tw.bundled.mjs --from-stdin
 */
async function main() {
  if (process.argv.length !== 3) {
    console.warn('Please use with one argument exactly');
    process.exitCode = 1;
    return;
  }
  const target = process.argv[2];

  const resolvedWithJest = new Set([
    ...(await resolveDependenciesWithJest(target, { isEE: true })),
    ...(await resolveDependenciesWithJest(target)),
  ]);

  console.log(
    Array.from(resolvedWithJest)
      .sort()
      .filter((x) => {
        return x.endsWith('.vue') || x.endsWith('.js');
      })
      .filter((x) => {
        return x.includes('app/assets/');
      })
      .join('\n'),
  );
}

main();
