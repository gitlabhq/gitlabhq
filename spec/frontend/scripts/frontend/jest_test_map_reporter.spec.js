/* eslint-disable no-console */
import fs from 'fs';
import path from 'path';
import JestTestMapReporter from '../../../../scripts/frontend/jest_test_map_reporter';

jest.mock('fs');

describe('JestTestMapReporter', () => {
  let reporter;
  let globalConfig;
  let reporterOptions;

  beforeEach(() => {
    globalConfig = {
      collectCoverage: true,
    };
    reporterOptions = {};

    reporter = new JestTestMapReporter(globalConfig, reporterOptions);

    jest.spyOn(console, 'log').mockImplementation();
    jest.spyOn(console, 'error').mockImplementation();
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('constructor', () => {
    it('initializes with correct default values', () => {
      expect(reporter.globalConfig).toBe(globalConfig);
      expect(reporter.options).toEqual({});
      expect(reporter.coverageEnabled).toBe(true);
      expect(reporter.testToSourceMap).toEqual({});
      expect(reporter.sourceToTestMap).toEqual({});
    });

    it('sets coverageEnabled to false when collectCoverage is false', () => {
      const config = { collectCoverage: false };
      const testReporter = new JestTestMapReporter(config);

      expect(testReporter.coverageEnabled).toBe(false);
    });

    it('accepts and stores reporter options', () => {
      const options = { outputDir: 'custom-dir' };
      const testReporter = new JestTestMapReporter(globalConfig, options);

      expect(testReporter.options).toEqual(options);
    });
  });

  describe('onTestResult', () => {
    const mockCwd = '/project/root';

    beforeEach(() => {
      jest.spyOn(process, 'cwd').mockReturnValue(mockCwd);
    });

    it('does nothing when coverage is disabled', () => {
      reporter.coverageEnabled = false;
      const test = {};
      const testResult = {
        testFilePath: '/project/root/spec/frontend/user_spec.js',
        coverage: { 'app/user.js': {} },
      };

      reporter.onTestResult(test, testResult);

      expect(reporter.testToSourceMap).toEqual({});
      expect(reporter.sourceToTestMap).toEqual({});
    });

    it('does nothing when testResult has no coverage', () => {
      const test = {};
      const testResult = {
        testFilePath: '/project/root/spec/frontend/user_spec.js',
        coverage: null,
      };

      reporter.onTestResult(test, testResult);

      expect(reporter.testToSourceMap).toEqual({});
      expect(reporter.sourceToTestMap).toEqual({});
    });

    it('maps test file to source files from coverage data', () => {
      const test = {};
      const testResult = {
        testFilePath: '/project/root/spec/frontend/user_spec.js',
        coverage: {
          '/project/root/app/assets/javascripts/user.js': {},
          '/project/root/app/assets/javascripts/helper.js': {},
        },
      };

      reporter.onTestResult(test, testResult);

      expect(reporter.testToSourceMap).toEqual({
        'spec/frontend/user_spec.js': [
          'app/assets/javascripts/user.js',
          'app/assets/javascripts/helper.js',
        ],
      });
    });

    it('maps source files to test files', () => {
      const test = {};
      const testResult = {
        testFilePath: '/project/root/spec/frontend/user_spec.js',
        coverage: {
          '/project/root/app/assets/javascripts/user.js': {},
        },
      };

      reporter.onTestResult(test, testResult);

      expect(reporter.sourceToTestMap).toEqual({
        'app/assets/javascripts/user.js': ['spec/frontend/user_spec.js'],
      });
    });

    it('filters out node_modules files from source files', () => {
      const test = {};
      const testResult = {
        testFilePath: '/project/root/spec/frontend/user_spec.js',
        coverage: {
          '/project/root/app/assets/javascripts/user.js': {},
          '/project/root/node_modules/library/index.js': {},
        },
      };

      reporter.onTestResult(test, testResult);

      expect(reporter.testToSourceMap['spec/frontend/user_spec.js']).toEqual([
        'app/assets/javascripts/user.js',
      ]);
      expect(reporter.sourceToTestMap).not.toHaveProperty('node_modules/library/index.js');
    });

    it('filters out spec files from source files', () => {
      const test = {};
      const testResult = {
        testFilePath: '/project/root/spec/frontend/user_spec.js',
        coverage: {
          '/project/root/app/assets/javascripts/user.js': {},
          '/project/root/spec/frontend/helper_spec.js': {},
        },
      };

      reporter.onTestResult(test, testResult);

      expect(reporter.testToSourceMap['spec/frontend/user_spec.js']).toEqual([
        'app/assets/javascripts/user.js',
      ]);
      expect(reporter.sourceToTestMap).not.toHaveProperty('spec/frontend/helper_spec.js');
    });

    it('filters out non-source files (json, md, etc)', () => {
      const test = {};
      const testResult = {
        testFilePath: '/project/root/spec/frontend/user_spec.js',
        coverage: {
          '/project/root/app/assets/javascripts/user.js': {},
          '/project/root/package.json': {},
          '/project/root/README.md': {},
          '/project/root/config.yml': {},
        },
      };

      reporter.onTestResult(test, testResult);

      expect(reporter.testToSourceMap['spec/frontend/user_spec.js']).toEqual([
        'app/assets/javascripts/user.js',
      ]);
      expect(reporter.sourceToTestMap).not.toHaveProperty('package.json');
      expect(reporter.sourceToTestMap).not.toHaveProperty('README.md');
      expect(reporter.sourceToTestMap).not.toHaveProperty('config.yml');
    });

    it('handles empty coverage data (no source files covered)', () => {
      const test = {};
      const testResult = {
        testFilePath: '/project/root/spec/frontend/user_spec.js',
        coverage: {},
      };

      reporter.onTestResult(test, testResult);

      expect(reporter.testToSourceMap).toEqual({
        'spec/frontend/user_spec.js': [],
      });
      expect(reporter.sourceToTestMap).toEqual({});
    });

    it('handles coverage with only filtered files (results in empty array)', () => {
      const test = {};
      const testResult = {
        testFilePath: '/project/root/spec/frontend/user_spec.js',
        coverage: {
          '/project/root/node_modules/lib/index.js': {},
          '/project/root/package.json': {},
        },
      };

      reporter.onTestResult(test, testResult);

      expect(reporter.testToSourceMap['spec/frontend/user_spec.js']).toEqual([]);
      expect(reporter.sourceToTestMap).toEqual({});
    });

    it('handles multiple tests covering the same source file', () => {
      const test = {};
      const testResult1 = {
        testFilePath: '/project/root/spec/frontend/user_spec.js',
        coverage: {
          '/project/root/app/assets/javascripts/user.js': {},
        },
      };
      const testResult2 = {
        testFilePath: '/project/root/spec/frontend/profile_spec.js',
        coverage: {
          '/project/root/app/assets/javascripts/user.js': {},
        },
      };

      reporter.onTestResult(test, testResult1);
      reporter.onTestResult(test, testResult2);

      expect(reporter.sourceToTestMap['app/assets/javascripts/user.js']).toEqual([
        'spec/frontend/user_spec.js',
        'spec/frontend/profile_spec.js',
      ]);
    });

    it('does not duplicate test files when same test is processed multiple times', () => {
      const test = {};
      const testResult = {
        testFilePath: '/project/root/spec/frontend/user_spec.js',
        coverage: {
          '/project/root/app/assets/javascripts/user.js': {},
        },
      };

      reporter.onTestResult(test, testResult);
      reporter.onTestResult(test, testResult);

      expect(reporter.sourceToTestMap['app/assets/javascripts/user.js']).toEqual([
        'spec/frontend/user_spec.js',
      ]);
    });
  });

  describe('onRunComplete', () => {
    const outputDir = 'jest-test-mapping';
    const outputPath = path.join(outputDir, 'jest-source-to-test.json');

    beforeEach(() => {
      fs.existsSync.mockReturnValue(true);
      fs.mkdirSync.mockImplementation();
      fs.writeFileSync.mockImplementation();
    });

    it('does nothing when coverage is disabled', () => {
      reporter.coverageEnabled = false;

      reporter.onRunComplete();

      expect(fs.writeFileSync).not.toHaveBeenCalled();
      expect(console.log).not.toHaveBeenCalled();
    });

    it('creates output directory if it does not exist', () => {
      fs.existsSync.mockReturnValue(false);
      reporter.sourceToTestMap = {
        'app/assets/javascripts/user.js': ['spec/frontend/user_spec.js'],
      };

      reporter.onRunComplete();

      expect(fs.mkdirSync).toHaveBeenCalledWith(outputDir, { recursive: true });
    });

    it('does not create output directory if it already exists', () => {
      fs.existsSync.mockReturnValue(true);
      reporter.sourceToTestMap = {
        'app/assets/javascripts/user.js': ['spec/frontend/user_spec.js'],
      };

      reporter.onRunComplete();

      expect(fs.mkdirSync).not.toHaveBeenCalled();
    });

    it('writes source to test map in Crystalball format', () => {
      reporter.sourceToTestMap = {
        'app/assets/javascripts/user.js': ['spec/frontend/user_spec.js'],
      };

      reporter.onRunComplete();

      const expectedOutput = {
        'app/assets/javascripts/user.js': {
          spec: {
            frontend: {
              'user_spec.js': 1,
            },
          },
        },
      };

      expect(fs.writeFileSync).toHaveBeenCalledWith(
        outputPath,
        JSON.stringify(expectedOutput, null, 2),
        'utf8',
      );
    });

    it('logs success message with statistics', () => {
      reporter.testToSourceMap = {
        'spec/frontend/user_spec.js': ['app/assets/javascripts/user.js'],
        'spec/frontend/profile_spec.js': ['app/assets/javascripts/profile.js'],
      };
      reporter.sourceToTestMap = {
        'app/assets/javascripts/user.js': ['spec/frontend/user_spec.js'],
        'app/assets/javascripts/profile.js': ['spec/frontend/profile_spec.js'],
      };

      reporter.onRunComplete();

      expect(console.log).toHaveBeenCalledWith(
        expect.stringContaining(`Jest test map written to ${outputPath}`),
      );
      expect(console.log).toHaveBeenCalledWith(expect.stringContaining('Tests mapped: 2'));
      expect(console.log).toHaveBeenCalledWith(expect.stringContaining('Source files covered: 2'));
    });

    it('uses custom output directory when provided in options', () => {
      reporter.options = { outputDir: 'custom-output' };
      const customPath = path.join('custom-output', 'jest-source-to-test.json');
      reporter.sourceToTestMap = {
        'app/assets/javascripts/user.js': ['spec/frontend/user_spec.js'],
      };

      reporter.onRunComplete();

      expect(fs.writeFileSync).toHaveBeenCalledWith(customPath, expect.any(String), 'utf8');
    });

    it('handles file write errors gracefully', () => {
      const error = new Error('Permission denied');
      fs.writeFileSync.mockImplementation(() => {
        throw error;
      });
      reporter.sourceToTestMap = {
        'app/assets/javascripts/user.js': ['spec/frontend/user_spec.js'],
      };

      reporter.onRunComplete();

      expect(console.error).toHaveBeenCalledWith(
        expect.stringContaining('Failed to write test map: Permission denied'),
      );
    });

    it('handles empty source to test map', () => {
      reporter.sourceToTestMap = {};

      reporter.onRunComplete();

      const expectedOutput = {};

      expect(fs.writeFileSync).toHaveBeenCalledWith(
        outputPath,
        JSON.stringify(expectedOutput, null, 2),
        'utf8',
      );
    });
  });

  describe('getOutputDir', () => {
    it('returns custom output directory when provided', () => {
      reporter.options = { outputDir: 'custom-dir' };

      expect(reporter.getOutputDir()).toBe('custom-dir');
    });

    it('returns default output directory when not provided', () => {
      expect(reporter.getOutputDir()).toBe('jest-test-mapping');
    });
  });

  describe('static methods', () => {
    describe('convertToCrystalballFormat', () => {
      it('converts source to test map to Crystalball nested format', () => {
        const sourceToTestMap = {
          'app/assets/javascripts/user.js': ['spec/frontend/user_spec.js'],
        };

        const result = JestTestMapReporter.convertToCrystalballFormat(sourceToTestMap);

        expect(result).toEqual({
          'app/assets/javascripts/user.js': {
            spec: {
              frontend: {
                'user_spec.js': 1,
              },
            },
          },
        });
      });

      it('handles multiple test files for one source file', () => {
        const sourceToTestMap = {
          'app/assets/javascripts/user.js': [
            'spec/frontend/user_spec.js',
            'spec/frontend/profile_spec.js',
          ],
        };

        const result = JestTestMapReporter.convertToCrystalballFormat(sourceToTestMap);

        expect(result).toEqual({
          'app/assets/javascripts/user.js': {
            spec: {
              frontend: {
                'user_spec.js': 1,
                'profile_spec.js': 1,
              },
            },
          },
        });
      });

      it('handles empty source to test map', () => {
        const sourceToTestMap = {};

        const result = JestTestMapReporter.convertToCrystalballFormat(sourceToTestMap);

        expect(result).toEqual({});
      });

      it('handles source file with empty test array', () => {
        const sourceToTestMap = {
          'app/assets/javascripts/user.js': [],
        };

        const result = JestTestMapReporter.convertToCrystalballFormat(sourceToTestMap);

        expect(result).toEqual({
          'app/assets/javascripts/user.js': {},
        });
      });

      it('handles multiple source files', () => {
        const sourceToTestMap = {
          'app/assets/javascripts/user.js': ['spec/frontend/user_spec.js'],
          'app/assets/javascripts/profile.js': ['spec/frontend/profile_spec.js'],
        };

        const result = JestTestMapReporter.convertToCrystalballFormat(sourceToTestMap);

        expect(result).toEqual({
          'app/assets/javascripts/user.js': {
            spec: {
              frontend: {
                'user_spec.js': 1,
              },
            },
          },
          'app/assets/javascripts/profile.js': {
            spec: {
              frontend: {
                'profile_spec.js': 1,
              },
            },
          },
        });
      });
    });

    describe('buildNestedTestPaths', () => {
      it('builds nested structure from flat test file paths', () => {
        const testFiles = ['spec/frontend/user_spec.js'];

        const result = JestTestMapReporter.buildNestedTestPaths(testFiles);

        expect(result).toEqual({
          spec: {
            frontend: {
              'user_spec.js': 1,
            },
          },
        });
      });

      it('handles multiple test files in same directory', () => {
        const testFiles = ['spec/frontend/user_spec.js', 'spec/frontend/profile_spec.js'];

        const result = JestTestMapReporter.buildNestedTestPaths(testFiles);

        expect(result).toEqual({
          spec: {
            frontend: {
              'user_spec.js': 1,
              'profile_spec.js': 1,
            },
          },
        });
      });

      it('handles test files in different directories', () => {
        const testFiles = ['spec/frontend/user_spec.js', 'spec/backend/api_spec.js'];

        const result = JestTestMapReporter.buildNestedTestPaths(testFiles);

        expect(result).toEqual({
          spec: {
            frontend: {
              'user_spec.js': 1,
            },
            backend: {
              'api_spec.js': 1,
            },
          },
        });
      });

      it('handles deeply nested paths', () => {
        const testFiles = ['spec/frontend/components/user/profile_spec.js'];

        const result = JestTestMapReporter.buildNestedTestPaths(testFiles);

        expect(result).toEqual({
          spec: {
            frontend: {
              components: {
                user: {
                  'profile_spec.js': 1,
                },
              },
            },
          },
        });
      });

      it('handles empty array', () => {
        const testFiles = [];

        const result = JestTestMapReporter.buildNestedTestPaths(testFiles);

        expect(result).toEqual({});
      });

      it('handles single-level paths', () => {
        const testFiles = ['user_spec.js'];

        const result = JestTestMapReporter.buildNestedTestPaths(testFiles);

        expect(result).toEqual({
          'user_spec.js': 1,
        });
      });
    });

    describe('shouldIncludeSourceFile', () => {
      it('excludes node_modules files', () => {
        expect(JestTestMapReporter.shouldIncludeSourceFile('node_modules/lib/index.js')).toBe(
          false,
        );
        expect(JestTestMapReporter.shouldIncludeSourceFile('app/node_modules/lib/index.js')).toBe(
          false,
        );
      });

      it('excludes spec files', () => {
        expect(JestTestMapReporter.shouldIncludeSourceFile('spec/frontend/user_spec.js')).toBe(
          false,
        );
        expect(JestTestMapReporter.shouldIncludeSourceFile('app/user_spec.js')).toBe(false);
        expect(JestTestMapReporter.shouldIncludeSourceFile('app/user_spec.ts')).toBe(false);
        expect(JestTestMapReporter.shouldIncludeSourceFile('app/user_spec.jsx')).toBe(false);
        expect(JestTestMapReporter.shouldIncludeSourceFile('app/user_spec.tsx')).toBe(false);
      });

      it('excludes json, markdown, and yaml files', () => {
        expect(JestTestMapReporter.shouldIncludeSourceFile('package.json')).toBe(false);
        expect(JestTestMapReporter.shouldIncludeSourceFile('README.md')).toBe(false);
        expect(JestTestMapReporter.shouldIncludeSourceFile('config.yml')).toBe(false);
        expect(JestTestMapReporter.shouldIncludeSourceFile('config.yaml')).toBe(false);
        expect(JestTestMapReporter.shouldIncludeSourceFile('notes.txt')).toBe(false);
      });

      it('includes JavaScript and TypeScript source files', () => {
        expect(JestTestMapReporter.shouldIncludeSourceFile('app/assets/javascripts/user.js')).toBe(
          true,
        );
        expect(JestTestMapReporter.shouldIncludeSourceFile('app/assets/javascripts/user.ts')).toBe(
          true,
        );
        expect(JestTestMapReporter.shouldIncludeSourceFile('app/assets/javascripts/user.jsx')).toBe(
          true,
        );
        expect(JestTestMapReporter.shouldIncludeSourceFile('app/assets/javascripts/user.tsx')).toBe(
          true,
        );
      });

      it('includes other code files', () => {
        expect(JestTestMapReporter.shouldIncludeSourceFile('app/styles/main.css')).toBe(true);
        expect(JestTestMapReporter.shouldIncludeSourceFile('app/styles/main.scss')).toBe(true);
        expect(JestTestMapReporter.shouldIncludeSourceFile('app/templates/user.vue')).toBe(true);
      });
    });

    describe('relativePath', () => {
      const mockCwd = '/project/root';

      beforeEach(() => {
        jest.spyOn(process, 'cwd').mockReturnValue(mockCwd);
      });

      it('converts absolute path to relative path', () => {
        const absolutePath = '/project/root/app/assets/javascripts/user.js';

        const result = JestTestMapReporter.relativePath(absolutePath);

        expect(result).toBe('app/assets/javascripts/user.js');
      });

      it('removes leading ./ from relative paths', () => {
        const absolutePath = '/project/root/user.js';

        const result = JestTestMapReporter.relativePath(absolutePath);

        expect(result).toBe('user.js');
      });

      it('handles paths already relative to cwd', () => {
        const relativePath = 'app/user.js';
        // When path.relative gets a relative path, it might return it as-is or with ./
        const absolutePath = path.join(mockCwd, relativePath);

        const result = JestTestMapReporter.relativePath(absolutePath);

        expect(result).toBe(relativePath);
      });

      it('handles deeply nested paths', () => {
        const absolutePath = '/project/root/app/assets/javascripts/components/user/profile.js';

        const result = JestTestMapReporter.relativePath(absolutePath);

        expect(result).toBe('app/assets/javascripts/components/user/profile.js');
      });
    });
  });
});
