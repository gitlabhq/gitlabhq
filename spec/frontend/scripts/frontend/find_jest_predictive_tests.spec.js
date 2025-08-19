import { spawnSync } from 'node:child_process';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname } from 'node:path';

import {
  hasRequiredEnvironmentVariables,
  getChangedFiles,
  findJestTests,
  collectTests,
  logAndSaveMatchingTestFiles,
} from '../../../../scripts/frontend/find_jest_predictive_tests';

jest.mock('node:child_process');
jest.mock('node:fs');
jest.mock('node:path', () => ({
  ...jest.requireActual('node:path'),
  dirname: jest.fn(),
}));

describe('find_jest_predictive_tests', () => {
  let originalEnv;
  let consoleWarnSpy;
  let consoleErrorSpy;
  let processSpy;
  const mockChangedFiles = [
    'foo/bar.js',
    'spec/frontend/foo_spec.js',
    'app/assets/javascripts/foo.js',
  ];

  beforeEach(() => {
    originalEnv = { ...process.env };

    jest.clearAllMocks();

    consoleWarnSpy = jest.spyOn(console, 'warn').mockImplementation();
    consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation();
    processSpy = jest.spyOn(process, 'exitCode', 'set').mockImplementation();

    // Setup default environment variables
    process.env.JEST_MATCHING_TEST_FILES_PATH = '/tmp/jest_matching_tests.txt';
    process.env.GLCI_PREDICTIVE_MATCHING_JS_FILES_PATH = '/tmp/js_files.txt';
    process.env.GLCI_PREDICTIVE_CHANGED_FILES_PATH = '/tmp/changed_files.txt';
  });

  afterEach(() => {
    process.env = originalEnv;
    jest.restoreAllMocks();
  });

  describe('environment variable checks', () => {
    it('does not throw warning when all required env variables are set', () => {
      hasRequiredEnvironmentVariables();
      expect(consoleWarnSpy).not.toHaveBeenCalled();
    });

    it('warns when environment variables are missing', () => {
      delete process.env.JEST_MATCHING_TEST_FILES_PATH;
      delete process.env.GLCI_PREDICTIVE_MATCHING_JS_FILES_PATH;

      hasRequiredEnvironmentVariables();
      expect(processSpy).toHaveBeenCalledTimes(1);
      expect(consoleWarnSpy).toHaveBeenCalledWith(
        'Warning: Missing required environment variables: JEST_MATCHING_TEST_FILES_PATH, GLCI_PREDICTIVE_MATCHING_JS_FILES_PATH',
      );
      expect(consoleWarnSpy).toHaveBeenCalledWith('Some functionality may not work as expected.');
    });
  });

  describe('find changed files', () => {
    it('reads and combines files from both sources', () => {
      readFileSync.mockImplementation((path) => {
        if (path === '/tmp/js_files.txt') {
          return 'app/assets/javascripts/foo.js\napp/assets/javascripts/bar.js';
        }
        if (path === '/tmp/changed_files.txt') {
          return 'spec/frontend/foo_spec.js\napp/assets/javascripts/bar.js';
        }
        return '';
      });

      const files = getChangedFiles();

      expect(files).toEqual(
        expect.arrayContaining([
          'app/assets/javascripts/foo.js',
          'app/assets/javascripts/bar.js',
          'spec/frontend/foo_spec.js',
        ]),
      );
      expect(readFileSync).toHaveBeenCalledTimes(2);
    });

    it('handles empty files gracefully', () => {
      readFileSync.mockReturnValue('');

      const files = getChangedFiles();

      expect(files).toEqual([]);
    });

    it('handles files with extra whitespace', () => {
      readFileSync.mockReturnValue('  file1.js  \n\n  file2.js  \n  ');

      const files = getChangedFiles();

      expect(files).toEqual(['file1.js', 'file2.js']);
    });

    it('warns when files cannot be read', () => {
      readFileSync.mockImplementation(() => {
        throw new Error('File not found');
      });

      const files = getChangedFiles();

      expect(files).toEqual([]);
      expect(consoleWarnSpy).toHaveBeenCalledTimes(2);
    });

    it('deduplicates files across sources', () => {
      readFileSync.mockReturnValue('duplicate.js\nduplicate.js\nunique.js');

      const files = getChangedFiles();

      expect(files).toEqual(['duplicate.js', 'unique.js']);
    });
  });

  describe('Find and list jest tests', () => {
    it('returns full test list', () => {
      spawnSync.mockReturnValue({
        status: 0,
        stdout: Array(100)
          .fill(0)
          .map((_, index) => `spec/frontend/${index}_spec.js`)
          .join('\n'),
        stderr: '',
      });

      const result = findJestTests('jest.config.js');

      expect(result).toHaveLength(100);
    });

    it('returns empty array for empty changed files', () => {
      const result = findJestTests('jest.config.js', []);

      expect(result).toEqual([]);
      expect(spawnSync).not.toHaveBeenCalled();
    });

    it('spawns jest with correct arguments', () => {
      spawnSync.mockReturnValue({
        status: 0,
        stdout: 'spec/frontend/foo_spec.js\nspec/frontend/bar_spec.js',
        stderr: '',
      });

      const changedFiles = ['app/assets/javascripts/foo.js'];
      const config = 'jest.config.js';

      findJestTests(config, changedFiles);

      expect(spawnSync).toHaveBeenCalledWith(
        expect.stringContaining('node_modules/.bin/jest'),
        [
          '--ci',
          '--config',
          'jest.config.js',
          '--listTests',
          '--findRelatedTests',
          'app/assets/javascripts/foo.js',
        ],
        {
          encoding: 'utf8',
          stdio: 'pipe',
          env: process.env,
        },
      );
    });

    it('filters out non-test files from output', () => {
      spawnSync.mockReturnValue({
        status: 0,
        stdout: `
          Determining test suites to run...
          spec/frontend/components/alert_spec.js
          spec/frontend/components/button_spec.js
          ee/spec/frontend/components/chart_spec.js
          Test Suites: 3 tests total
        `,
        stderr: '',
      });

      const changedFiles = ['components/alert.js'];
      const result = findJestTests('jest.config.js', changedFiles);

      expect(result).toEqual([
        'spec/frontend/components/alert_spec.js',
        'spec/frontend/components/button_spec.js',
        'ee/spec/frontend/components/chart_spec.js',
      ]);
    });

    it('throws error when jest fails', () => {
      const status = 11;
      const stderr = 'Jest configuration error';

      spawnSync.mockReturnValue({
        status,
        stdout: '',
        stderr,
      });

      const changedFiles = ['foo.js'];

      expect(() => {
        findJestTests('jest.config.js', changedFiles);
      }).toThrow(
        `Failed to run Jest with config jest.config.js: Jest exited with code ${status}: ${stderr}`,
      );
    });

    it('handles absolute paths correctly', () => {
      const cwd = process.cwd();
      spawnSync.mockReturnValue({
        status: 0,
        stdout: `${cwd}/spec/frontend/foo_spec.js\n${cwd}/ee/spec/frontend/bar_spec.js`,
        stderr: '',
      });

      const changedFiles = ['foo.js'];
      const result = findJestTests('jest.config.js', changedFiles);

      expect(result).toEqual(['spec/frontend/foo_spec.js', 'ee/spec/frontend/bar_spec.js']);
    });
  });

  describe('collectTests', () => {
    it('returns empty array when no changed files', () => {
      const result = collectTests([]);

      expect(spawnSync).not.toHaveBeenCalled();
      expect(result).toEqual([]);
    });

    it('collects tests from both unit and integration configs', () => {
      spawnSync.mockImplementation((_, args) => {
        const config = args[2]; // --config value
        if (config === 'jest.config.js') {
          return {
            status: 0,
            stdout: 'spec/frontend/foo_spec.js\nspec/frontend/bar_spec.js',
          };
        }
        if (config === 'jest.config.integration.js') {
          return {
            status: 0,
            stdout: 'spec/frontend_integration/baz_spec.js',
          };
        }
        return { status: 1, stderr: 'Unknown config' };
      });

      const result = collectTests(mockChangedFiles);

      expect(result).toEqual([
        'spec/frontend/bar_spec.js',
        'spec/frontend/foo_spec.js',
        'spec/frontend_integration/baz_spec.js',
      ]);
    });

    it('deduplicates tests across configs', () => {
      spawnSync.mockReturnValue({
        status: 0,
        stdout: 'spec/frontend/foo_spec.js\nspec/frontend/foo_spec.js',
      });

      const result = collectTests(mockChangedFiles);

      expect(result).toEqual(['spec/frontend/foo_spec.js']);
    });

    it('continues when one config fails', () => {
      spawnSync.mockImplementation((_, args) => {
        const config = args[2];
        if (config === 'jest.config.js') {
          return { status: 1, stderr: 'Config error' };
        }
        return {
          status: 0,
          stdout: 'spec/frontend_integration/test_spec.js',
        };
      });

      const result = collectTests(mockChangedFiles);

      expect(result).toEqual(['spec/frontend_integration/test_spec.js']);
      expect(consoleErrorSpy).toHaveBeenCalledTimes(1);
    });

    it('sorts tests alphabetically', () => {
      spawnSync.mockReturnValue({
        status: 0,
        stdout: 'spec/frontend/z_spec.js\nspec/frontend/a_spec.js\nspec/frontend/m_spec.js',
      });

      const result = collectTests(mockChangedFiles);

      expect(result).toEqual([
        'spec/frontend/a_spec.js',
        'spec/frontend/m_spec.js',
        'spec/frontend/z_spec.js',
      ]);
    });
  });

  describe('logAndSaveMatchingTestFiles', () => {
    beforeEach(() => {
      spawnSync.mockReturnValue({
        status: 0,
        stdout: 'spec/frontend/foo_spec.js\nspec/frontend/bar_spec.js',
      });
      dirname.mockReturnValue('/tmp');
    });

    it('saves test files output', () => {
      logAndSaveMatchingTestFiles(mockChangedFiles);

      expect(mkdirSync).toHaveBeenCalledWith('/tmp', { recursive: true });
      expect(writeFileSync).toHaveBeenCalledWith(
        '/tmp/jest_matching_tests.txt',
        'spec/frontend/bar_spec.js spec/frontend/foo_spec.js',
      );
    });

    it('formats output as space separated values for CI consumption', () => {
      logAndSaveMatchingTestFiles(mockChangedFiles);

      expect(writeFileSync).toHaveBeenCalledWith(
        expect.any(String),
        expect.stringMatching(/^[^\n]+( [^\n]+)*$/),
      );
    });

    it('does not save when JEST_MATCHING_TEST_FILES_PATH is not set', () => {
      delete process.env.JEST_MATCHING_TEST_FILES_PATH;

      logAndSaveMatchingTestFiles(mockChangedFiles);

      expect(mkdirSync).not.toHaveBeenCalled();
      expect(writeFileSync).not.toHaveBeenCalled();
    });

    it('handles empty test results', () => {
      spawnSync.mockReturnValue({
        status: 0,
        stdout: '',
      });

      logAndSaveMatchingTestFiles(mockChangedFiles);

      expect(writeFileSync).toHaveBeenCalledWith('/tmp/jest_matching_tests.txt', '');
    });

    it('creates nested directories if needed', () => {
      process.env.JEST_MATCHING_TEST_FILES_PATH = '/deeply/nested/path/tests.txt';
      dirname.mockReturnValue('/deeply/nested/path');

      logAndSaveMatchingTestFiles(mockChangedFiles);

      expect(mkdirSync).toHaveBeenCalledWith('/deeply/nested/path', { recursive: true });
      expect(writeFileSync).toHaveBeenCalledWith(
        '/deeply/nested/path/tests.txt',
        'spec/frontend/bar_spec.js spec/frontend/foo_spec.js',
      );
    });
  });
});
