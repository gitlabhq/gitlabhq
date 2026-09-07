import { describe, it, expect } from 'vitest';
import {
  findDuplicatedModules,
  simulateLanes,
} from '../../../../scripts/frontend/infection_scanner/duplicated_modules';

const ROOT = '/repo';
const abs = (relativePath) => `${ROOT}/${relativePath}`;

const buildGraph = (description) =>
  Object.fromEntries(
    Object.entries(description).map(([file, { imports = [], singletons }]) => [
      abs(file),
      {
        imports: imports.map((entry) =>
          typeof entry === 'string'
            ? { source: `./${entry}`, resolved: abs(entry) }
            : { source: entry.source, resolved: abs(entry.file) },
        ),
        ...(singletons ? { singletons } : {}),
      },
    ]),
  );

const pageOf = (entry, seeds) => [
  {
    entry,
    seeds: seeds.map((relativePath) => ({ file: abs(relativePath), infected: true })),
  },
];

const infectableExcept = (...cleanPaths) => {
  const clean = new Set(cleanPaths.map((relativePath) => abs(relativePath)));
  return (file) => !clean.has(file);
};

describe('scripts/frontend/infection_scanner/duplicated_modules', () => {
  describe('findDuplicatedModules', () => {
    const graph = buildGraph({
      'page.js': { imports: ['passthrough.js', 'widget.js'] },
      'passthrough.js': { imports: ['store.js'] },
      'widget.js': { imports: ['store.js'] },
      'store.js': { singletons: ['pinia-store'] },
    });
    const pages = pageOf('pages.thing', ['page.js']);

    it('reports nothing when every module in the page is infectable', () => {
      const findings = findDuplicatedModules({
        graph,
        pages,
        isInfectable: infectableExcept(),
        rootPath: ROOT,
      });

      expect(findings).toEqual([]);
    });

    it('reports a singleton reached in both lanes, naming the clean sink', () => {
      const findings = findDuplicatedModules({
        graph,
        pages,
        isInfectable: infectableExcept('passthrough.js'),
        rootPath: ROOT,
      });

      expect(findings).toHaveLength(1);
      expect(findings[0]).toMatchObject({
        page: 'pages.thing',
        module: 'store.js',
        singletons: ['pinia-store'],
        sink: 'passthrough.js',
      });
    });

    it('reports the chain with the lane of each step', () => {
      const [finding] = findDuplicatedModules({
        graph,
        pages,
        isInfectable: infectableExcept('passthrough.js'),
        rootPath: ROOT,
      });

      expect(finding.chain).toEqual([
        { file: 'page.js', infected: true },
        { file: 'passthrough.js', infected: false },
        { file: 'store.js', infected: false },
      ]);
    });

    it('does not report a module reached in both lanes that holds no singleton', () => {
      const withoutSingleton = buildGraph({
        'page.js': { imports: ['passthrough.js', 'widget.js'] },
        'passthrough.js': { imports: ['helper.js'] },
        'widget.js': { imports: ['helper.js'] },
        'helper.js': {},
      });

      const findings = findDuplicatedModules({
        graph: withoutSingleton,
        pages,
        isInfectable: infectableExcept('passthrough.js'),
        rootPath: ROOT,
      });

      expect(findings).toEqual([]);
    });

    it('does not report a third-party module, whose duplication is intended', () => {
      const thirdParty = buildGraph({
        'page.js': { imports: ['passthrough.js', 'widget.js'] },
        'passthrough.js': { imports: ['node_modules/pinia/index.js'] },
        'widget.js': { imports: ['node_modules/pinia/index.js'] },
        'node_modules/pinia/index.js': { singletons: ['pinia-instance'] },
      });

      const findings = findDuplicatedModules({
        graph: thirdParty,
        pages,
        isInfectable: infectableExcept('passthrough.js'),
        rootPath: ROOT,
      });

      expect(findings).toEqual([]);
    });

    it('walks every seed, so an ancestor page entry can be the one that duplicates', () => {
      const twoRoots = buildGraph({
        'ancestor.js': { imports: ['passthrough.js'] },
        'leaf.js': { imports: ['widget.js'] },
        'passthrough.js': { imports: ['store.js'] },
        'widget.js': { imports: ['store.js'] },
        'store.js': { singletons: ['pinia-store'] },
      });

      const findings = findDuplicatedModules({
        graph: twoRoots,
        pages: pageOf('pages.thing', ['ancestor.js', 'leaf.js']),
        isInfectable: infectableExcept('passthrough.js'),
        rootPath: ROOT,
      });

      expect(findings).toHaveLength(1);
      expect(findings[0].sink).toBe('passthrough.js');
    });

    describe('with an explicit ?vue3 import', () => {
      const optionTwo = buildGraph({
        'page.js': {
          imports: [{ source: './tree?vue3', file: 'tree.js' }, 'header.js'],
        },
        'tree.js': { imports: ['store.js'] },
        'header.js': { imports: ['store.js'] },
        'store.js': { singletons: ['pinia-store'] },
      });
      const flagOff = [
        { entry: 'pages.thing', flagState: 'flag off',
          seeds: [{ file: abs('page.js'), infected: false }] },
      ];

      it('reports a duplicate even though the page entry is clean', () => {
        const findings = findDuplicatedModules({
          graph: optionTwo,
          pages: flagOff,
          isInfectable: infectableExcept(),
          rootPath: ROOT,
        });

        expect(findings).toHaveLength(1);
        expect(findings[0].module).toBe('store.js');
      });

      it('reports no sink, because no clean module is to blame', () => {
        const [finding] = findDuplicatedModules({
          graph: optionTwo,
          pages: flagOff,
          isInfectable: infectableExcept(),
          rootPath: ROOT,
        });

        expect(finding.sink).toBeNull();
      });
    });

    describe('duplicationExpected', () => {
      const options = {
        graph,
        pages,
        isInfectable: infectableExcept('passthrough.js'),
        rootPath: ROOT,
      };

      it('suppresses a listed module', () => {
        expect(findDuplicatedModules({ ...options, duplicationExpected: ['store.js'] })).toEqual([]);
      });

      it('leaves other duplicated modules on the same page reported', () => {
        expect(findDuplicatedModules({ ...options, duplicationExpected: ['other.js'] })).toHaveLength(1);
      });
    });
  });

  describe('simulateLanes', () => {
    it('puts a module reached both ways into both sets', () => {
      const graph = buildGraph({
        'page.js': { imports: ['passthrough.js', 'widget.js'] },
        'passthrough.js': { imports: ['store.js'] },
        'widget.js': { imports: ['store.js'] },
        'store.js': {},
      });

      const { infected, clean } = simulateLanes({
        graph,
        seeds: [{ file: abs('page.js'), infected: true }],
        isInfectable: infectableExcept('passthrough.js'),
      });

      expect(infected.has(abs('store.js'))).toBe(true);
      expect(clean.has(abs('store.js'))).toBe(true);
      expect(clean.has(abs('page.js'))).toBe(false);
    });

    it('terminates on a cycle', () => {
      const graph = buildGraph({
        'a.js': { imports: ['b.js'] },
        'b.js': { imports: ['a.js'] },
      });

      const { infected } = simulateLanes({
        graph,
        seeds: [{ file: abs('a.js'), infected: true }],
        isInfectable: infectableExcept(),
      });

      expect([...infected].sort()).toEqual([abs('a.js'), abs('b.js')]);
    });
  });
});
