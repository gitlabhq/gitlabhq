import { uniqueId } from 'lodash';
import {
  mapToScopesViewModel,
  mapFromScopesViewModel,
  createNewEnvironmentScope,
  mapStrategiesToViewModel,
  mapStrategiesToRails,
} from '~/feature_flags/store/helpers';
import {
  ROLLOUT_STRATEGY_ALL_USERS,
  ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
  ROLLOUT_STRATEGY_USER_ID,
  PERCENT_ROLLOUT_GROUP_ID,
  INTERNAL_ID_PREFIX,
  DEFAULT_PERCENT_ROLLOUT,
  LEGACY_FLAG,
  NEW_VERSION_FLAG,
} from '~/feature_flags/constants';

describe('feature flags helpers spec', () => {
  describe('mapToScopesViewModel', () => {
    it('converts the data object from the Rails API into something more usable by Vue', () => {
      const input = [
        {
          id: 3,
          environment_scope: 'environment_scope',
          active: true,
          can_update: true,
          protected: true,
          strategies: [
            {
              name: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
              parameters: {
                percentage: '56',
              },
            },
            {
              name: ROLLOUT_STRATEGY_USER_ID,
              parameters: {
                userIds: '123,234',
              },
            },
          ],

          _destroy: true,
        },
      ];

      const expected = [
        expect.objectContaining({
          id: 3,
          environmentScope: 'environment_scope',
          active: true,
          canUpdate: true,
          protected: true,
          rolloutStrategy: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
          rolloutPercentage: '56',
          rolloutUserIds: '123, 234',
          shouldBeDestroyed: true,
        }),
      ];

      const actual = mapToScopesViewModel(input);

      expect(actual).toEqual(expected);
    });

    it('returns Boolean properties even when their Rails counterparts were not provided (are `undefined`)', () => {
      const input = [
        {
          id: 3,
          environment_scope: 'environment_scope',
        },
      ];

      const [result] = mapToScopesViewModel(input);

      expect(result).toEqual(
        expect.objectContaining({
          active: false,
          canUpdate: false,
          protected: false,
          shouldBeDestroyed: false,
        }),
      );
    });

    it('returns an empty array if null or undefined is provided as a parameter', () => {
      expect(mapToScopesViewModel(null)).toEqual([]);
      expect(mapToScopesViewModel(undefined)).toEqual([]);
    });

    describe('with user IDs per environment', () => {
      let oldGon;

      beforeEach(() => {
        oldGon = window.gon;
        window.gon = { features: { featureFlagsUsersPerEnvironment: true } };
      });

      afterEach(() => {
        window.gon = oldGon;
      });

      it('sets the user IDs as a comma separated string', () => {
        const input = [
          {
            id: 3,
            environment_scope: 'environment_scope',
            active: true,
            can_update: true,
            protected: true,
            strategies: [
              {
                name: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
                parameters: {
                  percentage: '56',
                },
              },
              {
                name: ROLLOUT_STRATEGY_USER_ID,
                parameters: {
                  userIds: '123,234',
                },
              },
            ],

            _destroy: true,
          },
        ];

        const expected = [
          {
            id: 3,
            environmentScope: 'environment_scope',
            active: true,
            canUpdate: true,
            protected: true,
            rolloutStrategy: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
            rolloutPercentage: '56',
            rolloutUserIds: '123, 234',
            shouldBeDestroyed: true,
            shouldIncludeUserIds: true,
          },
        ];

        const actual = mapToScopesViewModel(input);

        expect(actual).toEqual(expected);
      });
    });
  });

  describe('mapFromScopesViewModel', () => {
    it('converts the object emitted from the Vue component into an object than is in the right format to be submitted to the Rails API', () => {
      const input = {
        name: 'name',
        description: 'description',
        active: true,
        scopes: [
          {
            id: 4,
            environmentScope: 'environmentScope',
            active: true,
            canUpdate: true,
            protected: true,
            shouldBeDestroyed: true,
            shouldIncludeUserIds: true,
            rolloutStrategy: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
            rolloutPercentage: '48',
            rolloutUserIds: '123, 234',
          },
        ],
      };

      const expected = {
        operations_feature_flag: {
          name: 'name',
          description: 'description',
          active: true,
          version: LEGACY_FLAG,
          scopes_attributes: [
            {
              id: 4,
              environment_scope: 'environmentScope',
              active: true,
              can_update: true,
              protected: true,
              _destroy: true,
              strategies: [
                {
                  name: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
                  parameters: {
                    groupId: PERCENT_ROLLOUT_GROUP_ID,
                    percentage: '48',
                  },
                },
                {
                  name: ROLLOUT_STRATEGY_USER_ID,
                  parameters: {
                    userIds: '123,234',
                  },
                },
              ],
            },
          ],
        },
      };

      const actual = mapFromScopesViewModel(input);

      expect(actual).toEqual(expected);
    });

    it('should strip out internal IDs', () => {
      const input = {
        scopes: [{ id: 3 }, { id: uniqueId(INTERNAL_ID_PREFIX) }],
      };

      const result = mapFromScopesViewModel(input);
      const [realId, internalId] = result.operations_feature_flag.scopes_attributes;

      expect(realId.id).toBe(3);
      expect(internalId.id).toBeUndefined();
    });

    it('returns scopes_attributes as [] if param.scopes is null or undefined', () => {
      let {
        operations_feature_flag: { scopes_attributes: actualScopes },
      } = mapFromScopesViewModel({ scopes: null });

      expect(actualScopes).toEqual([]);

      ({
        operations_feature_flag: { scopes_attributes: actualScopes },
      } = mapFromScopesViewModel({ scopes: undefined }));

      expect(actualScopes).toEqual([]);
    });
    describe('with user IDs per environment', () => {
      it('sets the user IDs as a comma separated string', () => {
        const input = {
          name: 'name',
          description: 'description',
          active: true,
          scopes: [
            {
              id: 4,
              environmentScope: 'environmentScope',
              active: true,
              canUpdate: true,
              protected: true,
              shouldBeDestroyed: true,
              rolloutStrategy: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
              rolloutPercentage: '48',
              rolloutUserIds: '123, 234',
              shouldIncludeUserIds: true,
            },
          ],
        };

        const expected = {
          operations_feature_flag: {
            name: 'name',
            description: 'description',
            version: LEGACY_FLAG,
            active: true,
            scopes_attributes: [
              {
                id: 4,
                environment_scope: 'environmentScope',
                active: true,
                can_update: true,
                protected: true,
                _destroy: true,
                strategies: [
                  {
                    name: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
                    parameters: {
                      groupId: PERCENT_ROLLOUT_GROUP_ID,
                      percentage: '48',
                    },
                  },
                  {
                    name: ROLLOUT_STRATEGY_USER_ID,
                    parameters: {
                      userIds: '123,234',
                    },
                  },
                ],
              },
            ],
          },
        };

        const actual = mapFromScopesViewModel(input);

        expect(actual).toEqual(expected);
      });
    });
  });

  describe('createNewEnvironmentScope', () => {
    it('should return a new environment scope object populated with the default options', () => {
      const expected = {
        environmentScope: '',
        active: false,
        id: expect.stringContaining(INTERNAL_ID_PREFIX),
        rolloutStrategy: ROLLOUT_STRATEGY_ALL_USERS,
        rolloutPercentage: DEFAULT_PERCENT_ROLLOUT,
        rolloutUserIds: '',
      };

      const actual = createNewEnvironmentScope();

      expect(actual).toEqual(expected);
    });

    it('should return a new environment scope object with overrides applied', () => {
      const overrides = {
        environmentScope: 'environmentScope',
        active: true,
      };

      const expected = {
        environmentScope: 'environmentScope',
        active: true,
        id: expect.stringContaining(INTERNAL_ID_PREFIX),
        rolloutStrategy: ROLLOUT_STRATEGY_ALL_USERS,
        rolloutPercentage: DEFAULT_PERCENT_ROLLOUT,
        rolloutUserIds: '',
      };

      const actual = createNewEnvironmentScope(overrides);

      expect(actual).toEqual(expected);
    });

    it('sets canUpdate and protected when called with featureFlagPermissions=true', () => {
      expect(createNewEnvironmentScope({}, true)).toEqual(
        expect.objectContaining({
          canUpdate: true,
          protected: false,
        }),
      );
    });
  });

  describe('mapStrategiesToViewModel', () => {
    it('should map rails casing to view model casing', () => {
      expect(
        mapStrategiesToViewModel([
          {
            id: '1',
            name: 'default',
            parameters: {},
            scopes: [
              {
                environment_scope: '*',
                id: '1',
              },
            ],
          },
        ]),
      ).toEqual([
        {
          id: '1',
          name: 'default',
          parameters: {},
          shouldBeDestroyed: false,
          scopes: [
            {
              shouldBeDestroyed: false,
              environmentScope: '*',
              id: '1',
            },
          ],
        },
      ]);
    });

    it('inserts spaces between user ids', () => {
      const strategy = mapStrategiesToViewModel([
        {
          id: '1',
          name: 'userWithId',
          parameters: { userIds: 'user1,user2,user3' },
          scopes: [],
        },
      ])[0];

      expect(strategy.parameters).toEqual({ userIds: 'user1, user2, user3' });
    });
  });

  describe('mapStrategiesToRails', () => {
    it('should map rails casing to view model casing', () => {
      expect(
        mapStrategiesToRails({
          name: 'test',
          description: 'test description',
          version: NEW_VERSION_FLAG,
          active: true,
          strategies: [
            {
              id: '1',
              name: 'default',
              parameters: {},
              shouldBeDestroyed: true,
              scopes: [
                {
                  environmentScope: '*',
                  id: '1',
                  shouldBeDestroyed: true,
                },
              ],
            },
          ],
        }),
      ).toEqual({
        operations_feature_flag: {
          name: 'test',
          description: 'test description',
          version: NEW_VERSION_FLAG,
          active: true,
          strategies_attributes: [
            {
              id: '1',
              name: 'default',
              parameters: {},
              _destroy: true,
              scopes_attributes: [
                {
                  environment_scope: '*',
                  id: '1',
                  _destroy: true,
                },
              ],
            },
          ],
        },
      });
    });

    it('should insert a default * scope if there are none', () => {
      expect(
        mapStrategiesToRails({
          name: 'test',
          description: 'test description',
          version: NEW_VERSION_FLAG,
          active: true,
          strategies: [
            {
              id: '1',
              name: 'default',
              parameters: {},
              scopes: [],
            },
          ],
        }),
      ).toEqual({
        operations_feature_flag: {
          name: 'test',
          description: 'test description',
          version: NEW_VERSION_FLAG,
          active: true,
          strategies_attributes: [
            {
              id: '1',
              name: 'default',
              parameters: {},
              scopes_attributes: [
                {
                  environment_scope: '*',
                },
              ],
            },
          ],
        },
      });
    });

    it('removes white space between user ids', () => {
      const result = mapStrategiesToRails({
        name: 'test',
        version: NEW_VERSION_FLAG,
        active: true,
        strategies: [
          {
            id: '1',
            name: 'userWithId',
            parameters: { userIds: 'user1, user2, user3' },
            scopes: [],
          },
        ],
      });

      const strategyAttrs = result.operations_feature_flag.strategies_attributes[0];

      expect(strategyAttrs.parameters).toEqual({ userIds: 'user1,user2,user3' });
    });

    it('preserves the value of active', () => {
      const result = mapStrategiesToRails({
        name: 'test',
        version: NEW_VERSION_FLAG,
        active: false,
        strategies: [],
      });

      expect(result.operations_feature_flag.active).toBe(false);
    });
  });
});
