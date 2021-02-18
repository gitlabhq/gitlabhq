import { updateGroupPackagesSettingsOptimisticResponse } from '~/packages_and_registries/settings/group/graphql/utils/optimistic_responses';

describe('Optimistic responses', () => {
  describe('updateGroupPackagesSettingsOptimisticResponse', () => {
    it('returns the correct structure', () => {
      expect(updateGroupPackagesSettingsOptimisticResponse({ foo: 'bar' })).toMatchInlineSnapshot(`
        Object {
          "__typename": "Mutation",
          "updateNamespacePackageSettings": Object {
            "__typename": "UpdateNamespacePackageSettingsPayload",
            "errors": Array [],
            "packageSettings": Object {
              "foo": "bar",
            },
          },
        }
      `);
    });
  });
});
