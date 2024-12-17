#!/usr/bin/env node

import process from 'node:process';
import { compileAllStyles } from './lib/compile_css.mjs';

const fileWatcher = await compileAllStyles({ shouldWatch: process.argv?.includes('--watch') });

process.on('SIGTERM', () => {
  console.info('SIGTERM signal received.');
  fileWatcher?.close();
});
