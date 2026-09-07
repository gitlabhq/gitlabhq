import fs from 'fs';
import path from 'path';
import { sync as globSync } from 'glob';
import { baseEntryPoints, ALWAYS_LOADED_ENTRY_POINTS } from '../../../config/helpers/entry_points';

const ROOT = path.resolve(__dirname, '../../..');

const TEST_ONLY = ['coverage_persistence'];

const bundlesLoadedByLayouts = () => {
  const layouts = globSync('{,ee/,jh/}app/views/layouts/**/*.haml', { cwd: ROOT, absolute: true });
  const names = new Set();

  for (const layout of layouts) {
    const haml = fs.readFileSync(layout, 'utf-8');
    for (const [, name] of haml.matchAll(/webpack_bundle_tag ['"]([\w]+)['"]/g)) {
      names.add(name);
    }
  }
  return names;
};

describe('config/helpers/entry_points', () => {
  describe('ALWAYS_LOADED_ENTRY_POINTS', () => {
    it('names only real entry points', () => {
      const unknown = ALWAYS_LOADED_ENTRY_POINTS.filter((name) => !baseEntryPoints[name]);

      expect(unknown).toEqual([]);
    });

    it('matches the bundles the layouts load', () => {
      const expected = [...bundlesLoadedByLayouts()].filter((name) => !TEST_ONLY.includes(name));

      expect([...ALWAYS_LOADED_ENTRY_POINTS].sort()).toEqual(expected.sort());
    });

    it('excludes main, which is part of every page entry rather than a separate bundle', () => {
      expect(ALWAYS_LOADED_ENTRY_POINTS).not.toContain('default');
      expect(bundlesLoadedByLayouts()).not.toContain('main');
    });
  });
});
