import { describe, it, expect } from 'vitest';
import { detectSingletons } from '../../../../scripts/frontend/infection_scanner/singletons';

describe('scripts/frontend/infection_scanner/singletons', () => {
  describe('detectSingletons', () => {
    it.each([
      ['empty source', ''],
      ['undefined source', undefined],
      ['a module with no singleton', 'export const add = (a, b) => a + b;'],
    ])('returns an empty array for %s', (_, code) => {
      expect(detectSingletons(code)).toEqual([]);
    });

    it.each([
      ['export const with a store', "export const useThing = defineStore('thing', {});", ['pinia-store']],
      [
        'export const with the call wrapped onto the next line',
        "export const useThing =\n  defineStore('thing', {});",
        ['pinia-store'],
      ],
      ['export default', 'export default createEventHub();', ['event-hub']],
      ['a bare const', 'const hub = mitt();', ['event-hub']],
      ['a member-expression call', 'export default new Vuex.Store(getStoreConfig());', ['vuex-store']],
      [
        'an apollo client',
        "import createDefaultClient from '~/lib/graphql';\nexport const defaultClient = createDefaultClient(resolvers, config);",
        ['apollo-client'],
      ],
      [
        'an apollo client under a different local name',
        "import createClient from '~/lib/graphql';\nconst gitlabClient = createClient();",
        ['apollo-client'],
      ],
      [
        'an apollo client from a relative specifier',
        "import createClient from '../../lib/graphql';\nconst client = createClient();",
        ['apollo-client'],
      ],
      [
        'a customers dot client',
        "import { createCustomersDotClient } from 'ee/lib/customers_dot_graphql';\nconst client = createCustomersDotClient();",
        ['apollo-client'],
      ],
      ['a pinia instance', 'const pinia = createPinia();', ['pinia-instance']],
    ])('detects %s', (_, code, expected) => {
      expect(detectSingletons(code)).toEqual(expected);
    });

    it('reports every distinct kind a module declares, without duplicates', () => {
      const code = [
        "import createDefaultClient from '~/lib/graphql';",
        'export const defaultClient = createDefaultClient(resolvers, config);',
        'const second = new ApolloClient({});',
        'export const hub = mitt();',
      ].join('\n');

      expect(detectSingletons(code).sort()).toEqual(['apollo-client', 'event-hub']);
    });

    it('does not report a VueApollo provider', () => {
      const code = [
        "import VueApollo from 'vue-apollo';",
        'export default new VueApollo({ defaultClient });',
      ].join('\n');

      expect(detectSingletons(code)).toEqual([]);
    });

    it('does not report a non-factory import from lib/graphql', () => {
      const code = [
        "import { fetchPolicies } from '~/lib/graphql';",
        'export const policy = fetchPolicies(CACHE_FIRST);',
      ].join('\n');

      expect(detectSingletons(code)).toEqual([]);
    });

    describe('module scope', () => {
      it.each([
        ['an arrow-function factory', 'export const build = () => new Vuex.Store({});'],
        [
          'a function body',
          'export function build() {\n  const store = defineStore("x", {});\n  return store;\n}',
        ],
        [
          'an object property',
          'export const factories = {\n  thing: () => defineStore("x", {}),\n};',
        ],
        [
          'a call on the line after a blank line inside a function',
          'function build() {\n\n  const hub = mitt();\n  return hub;\n}',
        ],
      ])('does not detect a singleton in %s', (_, code) => {
        expect(detectSingletons(code)).toEqual([]);
      });

      it('does not detect a call that only appears in an import statement', () => {
        expect(detectSingletons("import { defineStore } from 'pinia';")).toEqual([]);
      });
    });

    describe('bare statements', () => {
      it('detects a module-scope Object.defineProperty', () => {
        const code = "Object.defineProperty(window, 'pendingApolloRequests', {\n  get() {},\n});";

        expect(detectSingletons(code)).toEqual(['define-property']);
      });

      it('does not detect one inside a function, which runs per call', () => {
        const code = 'export function attach(target) {\n  Object.defineProperty(target, "x", {});\n}';

        expect(detectSingletons(code)).toEqual([]);
      });
    });
  });
});
