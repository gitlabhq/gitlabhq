/* eslint-disable global-require */

import path from 'path';

import axios from '~/lib/utils/axios_utils';

const absPath = path.join.bind(null, __dirname);

jest.mock('fs');
jest.mock('readdir-enhanced');

describe('mocks_helper.js', () => {
  let setupManualMocks;
  const setMock = jest.fn().mockName('setMock');
  let fs;
  let readdir;

  beforeAll(() => {
    jest.resetModules();
    jest.setMock = jest.fn().mockName('jest.setMock');
    fs = require('fs');
    readdir = require('readdir-enhanced');

    // We need to provide setupManualMocks with a mock function that pretends to do the setup of
    // the mock. This is because we can't mock jest.setMock across files.
    setupManualMocks = () => require('./mocks_helper').setupManualMocks(setMock);
  });

  afterEach(() => {
    fs.existsSync.mockReset();
    readdir.sync.mockReset();
    setMock.mockReset();
  });

  it('enumerates through mock file roots', () => {
    setupManualMocks();
    expect(fs.existsSync).toHaveBeenCalledTimes(1);
    expect(fs.existsSync).toHaveBeenNthCalledWith(1, absPath('ce'));

    expect(readdir.sync).toHaveBeenCalledTimes(0);
  });

  it("doesn't traverse the directory tree infinitely", () => {
    fs.existsSync.mockReturnValue(true);
    readdir.sync.mockReturnValue([]);
    setupManualMocks();

    const readdirSpy = readdir.sync;
    expect(readdirSpy).toHaveBeenCalled();
    readdirSpy.mock.calls.forEach(call => {
      expect(call[1].deep).toBeLessThan(100);
    });
  });

  it('sets up mocks for CE (the ~/ prefix)', () => {
    fs.existsSync.mockImplementation(root => root.endsWith('ce'));
    readdir.sync.mockReturnValue(['root.js', 'lib/utils/util.js']);
    setupManualMocks();

    expect(readdir.sync).toHaveBeenCalledTimes(1);
    expect(readdir.sync.mock.calls[0][0]).toBe(absPath('ce'));

    expect(setMock).toHaveBeenCalledTimes(2);
    expect(setMock).toHaveBeenNthCalledWith(1, '~/root', './ce/root');
    expect(setMock).toHaveBeenNthCalledWith(2, '~/lib/utils/util', './ce/lib/utils/util');
  });

  it('sets up mocks for all roots', () => {
    const files = {
      [absPath('ce')]: ['root', 'lib/utils/util'],
      [absPath('node')]: ['jquery', '@babel/core'],
    };

    fs.existsSync.mockReturnValue(true);
    readdir.sync.mockImplementation(root => files[root]);
    setupManualMocks();

    expect(readdir.sync).toHaveBeenCalledTimes(1);
    expect(readdir.sync.mock.calls[0][0]).toBe(absPath('ce'));

    expect(setMock).toHaveBeenCalledTimes(2);
    expect(setMock).toHaveBeenNthCalledWith(1, '~/root', './ce/root');
    expect(setMock).toHaveBeenNthCalledWith(2, '~/lib/utils/util', './ce/lib/utils/util');
  });

  it('fails when given a virtual mock', () => {
    fs.existsSync.mockImplementation(p => p.endsWith('ce'));
    readdir.sync.mockReturnValue(['virtual', 'shouldntBeImported']);
    setMock.mockImplementation(() => {
      throw new Error('Could not locate module');
    });

    expect(setupManualMocks).toThrow(
      new Error("A manual mock was defined for module ~/virtual, but the module doesn't exist!"),
    );

    expect(readdir.sync).toHaveBeenCalledTimes(1);
    expect(readdir.sync.mock.calls[0][0]).toBe(absPath('ce'));
  });

  describe('auto-injection', () => {
    it('handles ambiguous paths', () => {
      jest.isolateModules(() => {
        const axios2 = require('../../../app/assets/javascripts/lib/utils/axios_utils').default;
        expect(axios2.isMock).toBe(true);
      });
    });

    it('survives jest.isolateModules()', done => {
      jest.isolateModules(() => {
        const axios2 = require('~/lib/utils/axios_utils').default;
        expect(axios2.isMock).toBe(true);
        done();
      });
    });

    it('can be unmocked and remocked', () => {
      jest.dontMock('~/lib/utils/axios_utils');
      jest.resetModules();
      const axios2 = require('~/lib/utils/axios_utils').default;
      expect(axios2).not.toBe(axios);
      expect(axios2.isMock).toBeUndefined();

      jest.doMock('~/lib/utils/axios_utils');
      jest.resetModules();
      const axios3 = require('~/lib/utils/axios_utils').default;
      expect(axios3).not.toBe(axios2);
      expect(axios3.isMock).toBe(true);
    });
  });
});
