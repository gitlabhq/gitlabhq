/**
 * @module
 *
 * This module implements auto-injected manual mocks that are cleaner than Jest's approach.
 *
 * See https://docs.gitlab.com/ee/development/testing_guide/frontend_testing.html
 */

import fs from 'fs';
import path from 'path';

import readdir from 'readdir-enhanced';

const MAX_DEPTH = 20;
const prefixMap = [
  // E.g. the mock ce/foo/bar maps to require path ~/foo/bar
  { mocksRoot: 'ce', requirePrefix: '~' },
  // { mocksRoot: 'ee', requirePrefix: 'ee' }, // We'll deal with EE-specific mocks later
  // { mocksRoot: 'virtual', requirePrefix: '' }, // We'll deal with virtual mocks later
];

const mockFileFilter = (stats) => stats.isFile() && stats.path.endsWith('.js');

const getMockFiles = (root) => readdir.sync(root, { deep: MAX_DEPTH, filter: mockFileFilter });

// Function that performs setting a mock. This has to be overridden by the unit test, because
// jest.setMock can't be overwritten across files.
// Use require() because jest.setMock expects the CommonJS exports object
const defaultSetMock = (srcPath, mockPath) =>
  jest.mock(srcPath, () => jest.requireActual(mockPath));

export const setupManualMocks = function setupManualMocks(setMock = defaultSetMock) {
  prefixMap.forEach(({ mocksRoot, requirePrefix }) => {
    const mocksRootAbsolute = path.join(__dirname, mocksRoot);
    if (!fs.existsSync(mocksRootAbsolute)) {
      return;
    }

    getMockFiles(path.join(__dirname, mocksRoot)).forEach((mockPath) => {
      const mockPathNoExt = mockPath.substring(0, mockPath.length - path.extname(mockPath).length);
      const sourcePath = path.join(requirePrefix, mockPathNoExt);
      const mockPathRelative = `./${path.join(mocksRoot, mockPathNoExt)}`;

      try {
        setMock(sourcePath, mockPathRelative);
      } catch (e) {
        if (e.message.includes('Could not locate module')) {
          // The corresponding mocked module doesn't exist. Raise a better error.
          // Eventualy, we may support virtual mocks (mocks whose path doesn't directly correspond
          // to a module, like with the `ee_else_ce` prefix).
          throw new Error(
            `A manual mock was defined for module ${sourcePath}, but the module doesn't exist!`,
          );
        }
      }
    });
  });
};
