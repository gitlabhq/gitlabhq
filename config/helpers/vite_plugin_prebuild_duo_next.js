import { spawnSync } from 'node:child_process';
import path from 'node:path';
import fs from 'node:fs';
import IS_EE from './is_ee_env';

export const PrebuildDuoNext = (options = {}) => {
  const {
    buildScript = 'scripts/build_frontend_islands',
    skipEnv = 'SKIP_PRE_LAUNCH', // set to "1" to bypass: SKIP_PRE_LAUNCH=1 vite dev
  } = options;

  let ran = false;

  return {
    name: 'prebuild-duo-next',
    apply: 'serve', // never runs in "vite build"
    enforce: 'pre',
    configureServer() {
      if (!IS_EE) return;
      if (ran) return;
      if (process.env[skipEnv]) return;

      const scriptPath = path.resolve(process.cwd(), buildScript);

      if (!fs.existsSync(scriptPath)) {
        throw new Error(`[prebuild-duo-next] Build script not found at ${scriptPath}`);
      }

      // Use bash explicitly to ensure cross-platform compatibility
      // The script has #!/usr/bin/env bash shebang, so this is the intended interpreter
      const res = spawnSync('bash', [scriptPath], {
        cwd: process.cwd(),
        stdio: 'inherit',
        env: process.env,
      });

      if (res.status !== 0) {
        console.warn(
          `[prebuild-duo-next] "${buildScript}" failed (code ${res.status}). Continuing with Vite startup - frontend islands will not be available.`,
        );
      } else {
        console.log('[prebuild-duo-next] Frontend islands build completed successfully');
      }

      ran = true;
    },
  };
};
