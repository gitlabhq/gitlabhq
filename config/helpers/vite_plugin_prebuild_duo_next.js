import { spawnSync } from 'node:child_process';
import path from 'node:path';
import fs from 'node:fs';

export const PrebuildDuoNext = (options = {}) => {
  const {
    appDir = 'ee/frontend_islands/apps/duo_next',
    command = 'yarn',
    args = ['build'],
    skipEnv = 'SKIP_PRE_LAUNCH', // set to "1" to bypass: SKIP_PRE_LAUNCH=1 vite dev
  } = options;

  let ran = false;

  return {
    name: 'prebuild-duo-next',
    apply: 'serve', // never runs in "vite build"
    enforce: 'pre',

    configureServer() {
      if (ran) return;
      if (process.env[skipEnv]) return;

      const cwd = path.resolve(process.cwd(), appDir);
      const pkg = path.join(cwd, 'package.json');

      if (!fs.existsSync(pkg)) {
        throw new Error(`[prebuild-duo-next] package.json not found at ${pkg}`);
      }

      const res = spawnSync(command, args, {
        cwd,
        stdio: 'inherit',
        shell: true,
        env: process.env,
      });

      if (res.status !== 0) {
        throw new Error(
          `[prebuild-duo-next] "${command} ${args.join(' ')}" failed in ${cwd} (code ${res.status})`,
        );
      }

      ran = true;
    },
  };
};
