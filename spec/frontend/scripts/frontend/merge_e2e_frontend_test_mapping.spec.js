/* eslint-disable no-console, import/no-commonjs */
const fs = require('fs');
const glob = require('glob');

jest.mock('fs');
jest.mock('glob');

// Import after mocking - using require ensures mocks are in place before module loads
const {
  loadE2EMappings,
  invertMapping,
  convertToCrystalballFormat,
  buildNestedTestPaths,
  loadJestMapping,
  mergeMappings,
  deepMergeTestPaths,
  saveMergedMapping,
  main,
} = require('../../../../scripts/frontend/merge_e2e_frontend_test_mapping');

describe('merge_e2e_frontend_test_mapping', () => {
  let originalConsoleLog;
  let originalConsoleWarn;
  let originalConsoleError;

  beforeEach(() => {
    originalConsoleLog = console.log;
    originalConsoleWarn = console.warn;
    originalConsoleError = console.error;
    console.log = jest.fn();
    console.warn = jest.fn();
    console.error = jest.fn();

    jest.clearAllMocks();
  });

  afterEach(() => {
    console.log = originalConsoleLog;
    console.warn = originalConsoleWarn;
    console.error = originalConsoleError;
  });

  describe('loadE2EMappings', () => {
    it('returns empty object when no E2E mapping files found', () => {
      glob.sync.mockReturnValue([]);

      const result = loadE2EMappings();

      expect(result).toEqual({});
      expect(console.log).toHaveBeenCalledWith('No E2E mapping files found');
    });

    it('loads and merges E2E mapping files', () => {
      glob.sync.mockReturnValue([
        'coverage-e2e-frontend/js-coverage-by-example-test1.json',
        'coverage-e2e-frontend/js-coverage-by-example-test2.json',
      ]);

      fs.readFileSync.mockImplementation((filePath) => {
        if (filePath.includes('test1')) {
          return JSON.stringify({
            'qa/specs/test1_spec.rb:1': ['app/assets/javascripts/a.js'],
          });
        }
        return JSON.stringify({
          'qa/specs/test2_spec.rb:1': ['app/assets/javascripts/b.js'],
        });
      });

      const result = loadE2EMappings();

      expect(result).toEqual({
        'qa/specs/test1_spec.rb:1': ['app/assets/javascripts/a.js'],
        'qa/specs/test2_spec.rb:1': ['app/assets/javascripts/b.js'],
      });
      expect(console.log).toHaveBeenCalledWith('Found 2 E2E mapping files');
    });

    it('handles invalid JSON gracefully', () => {
      glob.sync.mockReturnValue(['coverage-e2e-frontend/js-coverage-by-example-bad.json']);
      fs.readFileSync.mockReturnValue('invalid json');

      const result = loadE2EMappings();

      expect(result).toEqual({});
      expect(console.warn).toHaveBeenCalledWith(
        expect.stringContaining('Warning: Failed to parse'),
      );
    });

    it('deduplicates source paths for same test', () => {
      glob.sync.mockReturnValue([
        'coverage-e2e-frontend/js-coverage-by-example-job1.json',
        'coverage-e2e-frontend/js-coverage-by-example-job2.json',
      ]);

      fs.readFileSync.mockImplementation((filePath) => {
        if (filePath.includes('job1')) {
          return JSON.stringify({
            'qa/specs/test_spec.rb:1': ['app/assets/javascripts/shared.js'],
          });
        }
        return JSON.stringify({
          'qa/specs/test_spec.rb:1': ['app/assets/javascripts/shared.js'],
        });
      });

      const result = loadE2EMappings();

      expect(result['qa/specs/test_spec.rb:1']).toEqual(['app/assets/javascripts/shared.js']);
    });
  });

  describe('invertMapping', () => {
    it('inverts test -> sources to source -> tests', () => {
      const input = {
        'qa/specs/test_spec.rb:1': ['app/assets/javascripts/a.js', 'app/assets/javascripts/b.js'],
      };

      const result = invertMapping(input);

      expect(result).toEqual({
        'app/assets/javascripts/a.js': ['qa/specs/test_spec.rb:1'],
        'app/assets/javascripts/b.js': ['qa/specs/test_spec.rb:1'],
      });
    });

    it('normalizes paths by removing leading ./', () => {
      const input = {
        'qa/specs/test_spec.rb:1': ['./app/assets/javascripts/a.js'],
      };

      const result = invertMapping(input);

      expect(result['app/assets/javascripts/a.js']).toBeDefined();
      expect(result['./app/assets/javascripts/a.js']).toBeUndefined();
    });

    it('combines tests for same source file', () => {
      const input = {
        'qa/specs/test1_spec.rb:1': ['app/assets/javascripts/shared.js'],
        'qa/specs/test2_spec.rb:1': ['app/assets/javascripts/shared.js'],
      };

      const result = invertMapping(input);

      expect(result['app/assets/javascripts/shared.js']).toEqual([
        'qa/specs/test1_spec.rb:1',
        'qa/specs/test2_spec.rb:1',
      ]);
    });
  });

  describe('buildNestedTestPaths', () => {
    it('builds nested structure from test paths', () => {
      const testLocations = ['qa/specs/features/login_spec.rb:42'];

      const result = buildNestedTestPaths(testLocations);

      expect(result).toEqual({
        qa: {
          specs: {
            features: {
              'login_spec.rb:42': 1,
            },
          },
        },
      });
    });

    it('handles multiple tests in same directory', () => {
      const testLocations = ['qa/specs/test1_spec.rb:1', 'qa/specs/test2_spec.rb:1'];

      const result = buildNestedTestPaths(testLocations);

      expect(result).toEqual({
        qa: {
          specs: {
            'test1_spec.rb:1': 1,
            'test2_spec.rb:1': 1,
          },
        },
      });
    });
  });

  describe('convertToCrystalballFormat', () => {
    it('converts source -> tests mapping to Crystalball format', () => {
      const input = {
        'app/assets/javascripts/a.js': ['qa/specs/test_spec.rb:1'],
      };

      const result = convertToCrystalballFormat(input);

      expect(result).toEqual({
        'app/assets/javascripts/a.js': {
          qa: {
            specs: {
              'test_spec.rb:1': 1,
            },
          },
        },
      });
    });
  });

  describe('loadJestMapping', () => {
    it('returns null when Jest mapping file does not exist', () => {
      fs.existsSync.mockReturnValue(false);

      const result = loadJestMapping();

      expect(result).toBeNull();
      expect(console.log).toHaveBeenCalledWith(expect.stringContaining('Jest mapping not found'));
    });

    it('loads Jest mapping when file exists', () => {
      const jestData = {
        'app/assets/javascripts/a.js': {
          spec: { frontend: { 'a_spec.js': 1 } },
        },
      };
      fs.existsSync.mockReturnValue(true);
      fs.readFileSync.mockReturnValue(JSON.stringify(jestData));

      const result = loadJestMapping();

      expect(result).toEqual(jestData);
      expect(console.log).toHaveBeenCalledWith('Loaded Jest mapping: 1 source files');
    });

    it('returns null on JSON parse error', () => {
      fs.existsSync.mockReturnValue(true);
      fs.readFileSync.mockReturnValue('invalid json');

      const result = loadJestMapping();

      expect(result).toBeNull();
      expect(console.error).toHaveBeenCalledWith(
        expect.stringContaining('Failed to load Jest mapping'),
      );
    });
  });

  describe('deepMergeTestPaths', () => {
    it('merges nested test path structures', () => {
      const target = {
        spec: {
          frontend: {
            'a_spec.js': 1,
          },
        },
      };
      const source = {
        qa: {
          specs: {
            'test_spec.rb:1': 1,
          },
        },
      };

      const result = deepMergeTestPaths(target, source);

      expect(result).toEqual({
        spec: {
          frontend: {
            'a_spec.js': 1,
          },
        },
        qa: {
          specs: {
            'test_spec.rb:1': 1,
          },
        },
      });
    });

    it('deeply merges overlapping structures', () => {
      const target = {
        spec: {
          frontend: {
            'a_spec.js': 1,
          },
        },
      };
      const source = {
        spec: {
          frontend: {
            'b_spec.js': 1,
          },
        },
      };

      const result = deepMergeTestPaths(target, source);

      expect(result).toEqual({
        spec: {
          frontend: {
            'a_spec.js': 1,
            'b_spec.js': 1,
          },
        },
      });
    });
  });

  describe('mergeMappings', () => {
    it('merges Jest and E2E mappings', () => {
      const jestMapping = {
        'app/assets/javascripts/a.js': {
          spec: { frontend: { 'a_spec.js': 1 } },
        },
      };
      const e2eMapping = {
        'app/assets/javascripts/b.js': {
          qa: { specs: { 'test_spec.rb:1': 1 } },
        },
      };

      const result = mergeMappings(jestMapping, e2eMapping);

      expect(result).toEqual({
        'app/assets/javascripts/a.js': {
          spec: { frontend: { 'a_spec.js': 1 } },
        },
        'app/assets/javascripts/b.js': {
          qa: { specs: { 'test_spec.rb:1': 1 } },
        },
      });
    });

    it('merges tests for same source file', () => {
      const jestMapping = {
        'app/assets/javascripts/shared.js': {
          spec: { frontend: { 'shared_spec.js': 1 } },
        },
      };
      const e2eMapping = {
        'app/assets/javascripts/shared.js': {
          qa: { specs: { 'e2e_spec.rb:1': 1 } },
        },
      };

      const result = mergeMappings(jestMapping, e2eMapping);

      expect(result['app/assets/javascripts/shared.js']).toEqual({
        spec: { frontend: { 'shared_spec.js': 1 } },
        qa: { specs: { 'e2e_spec.rb:1': 1 } },
      });
    });
  });

  describe('saveMergedMapping', () => {
    it('creates output directory if it does not exist', () => {
      fs.existsSync.mockReturnValue(false);
      fs.mkdirSync.mockImplementation();
      fs.writeFileSync.mockImplementation();

      saveMergedMapping({ test: 'data' });

      expect(fs.mkdirSync).toHaveBeenCalledWith('jest-test-mapping', { recursive: true });
    });

    it('does not create directory if it exists', () => {
      fs.existsSync.mockReturnValue(true);
      fs.writeFileSync.mockImplementation();

      saveMergedMapping({ test: 'data' });

      expect(fs.mkdirSync).not.toHaveBeenCalled();
    });

    it('writes mapping to file', () => {
      fs.existsSync.mockReturnValue(true);
      fs.writeFileSync.mockImplementation();

      const mapping = { 'app/a.js': { spec: { 'a_spec.js': 1 } } };
      saveMergedMapping(mapping);

      expect(fs.writeFileSync).toHaveBeenCalledWith(
        'jest-test-mapping/merged-source-to-test.json',
        JSON.stringify(mapping, null, 2),
        'utf8',
      );
    });
  });

  describe('main', () => {
    beforeEach(() => {
      fs.existsSync.mockReturnValue(false);
      fs.mkdirSync.mockImplementation();
      fs.writeFileSync.mockImplementation();
    });

    it('skips when no E2E mappings exist', () => {
      glob.sync.mockReturnValue([]);

      main();

      expect(console.log).toHaveBeenCalledWith('No E2E mappings to merge, skipping...');
      expect(fs.writeFileSync).not.toHaveBeenCalled();
    });

    it('saves E2E mapping only when no Jest mapping exists', () => {
      glob.sync.mockReturnValue(['coverage-e2e-frontend/js-coverage-by-example-test.json']);
      fs.readFileSync.mockReturnValue(
        JSON.stringify({
          'qa/specs/test_spec.rb:1': ['app/assets/javascripts/a.js'],
        }),
      );
      fs.existsSync.mockReturnValue(false);

      main();

      expect(console.log).toHaveBeenCalledWith('No Jest mapping found, saving E2E mapping only');
      expect(fs.writeFileSync).toHaveBeenCalled();
    });

    it('merges E2E and Jest mappings when both exist', () => {
      glob.sync.mockReturnValue(['coverage-e2e-frontend/js-coverage-by-example-test.json']);

      const e2eData = {
        'qa/specs/test_spec.rb:1': ['app/assets/javascripts/shared.js'],
      };
      const jestData = {
        'app/assets/javascripts/shared.js': {
          spec: { frontend: { 'shared_spec.js': 1 } },
        },
      };

      fs.existsSync.mockImplementation((path) => {
        return path === 'jest-test-mapping/jest-source-to-test.json';
      });

      fs.readFileSync.mockImplementation((path) => {
        if (path.includes('js-coverage-by-example')) {
          return JSON.stringify(e2eData);
        }
        return JSON.stringify(jestData);
      });

      main();

      expect(console.log).toHaveBeenCalledWith(expect.stringContaining('Merged mapping:'));
      expect(fs.writeFileSync).toHaveBeenCalled();

      // Verify merged content
      const writeCall = fs.writeFileSync.mock.calls[0];
      const writtenData = JSON.parse(writeCall[1]);

      expect(writtenData['app/assets/javascripts/shared.js'].spec).toBeDefined();
      expect(writtenData['app/assets/javascripts/shared.js'].qa).toBeDefined();
    });
  });
});
