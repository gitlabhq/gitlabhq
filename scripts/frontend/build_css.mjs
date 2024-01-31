#!/usr/bin/env node

import process from 'node:process';
/* eslint-disable import/extensions */
import { compileAllStyles } from './lib/compile_css.mjs';
/* eslint-enable import/extensions */

const fileWatcher = await compileAllStyles({ shouldWatch: process.argv?.includes('--watch') });

process.on('SIGTERM', () => {
  console.info('SIGTERM signal received.');
  fileWatcher?.close();
});
