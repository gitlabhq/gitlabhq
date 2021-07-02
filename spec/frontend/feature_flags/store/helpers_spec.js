import { NEW_VERSION_FLAG } from '~/feature_flags/constants';
import { mapStrategiesToViewModel, mapStrategiesToRails } from '~/feature_flags/store/helpers';

describe('feature flags helpers spec', () => {
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
      const [strategy] = mapStrategiesToViewModel([
        {
          id: '1',
          name: 'userWithId',
          parameters: { userIds: 'user1,user2,user3' },
          scopes: [],
        },
      ]);

      expect(strategy.parameters).toEqual({ userIds: 'user1, user2, user3' });
    });
  });

  describe('mapStrategiesToRails', () => {
    it('should map rails casing to view model casing', () => {
      expect(
        mapStrategiesToRails({
          name: 'test',
          description: 'test description',
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
          active: true,
          version: NEW_VERSION_FLAG,
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
          active: true,
          version: NEW_VERSION_FLAG,
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
        active: false,
        strategies: [],
      });

      expect(result.operations_feature_flag.active).toBe(false);
    });
  });
});
