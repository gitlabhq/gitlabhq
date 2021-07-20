import { ROLLOUT_STRATEGY_GITLAB_USER_LIST, NEW_VERSION_FLAG } from '../constants';

const mapStrategyScopesToRails = (scopes) =>
  scopes.length === 0
    ? [{ environment_scope: '*' }]
    : scopes.map((s) => ({
        id: s.id,
        _destroy: s.shouldBeDestroyed,
        environment_scope: s.environmentScope,
      }));

const mapStrategyScopesToView = (scopes) =>
  scopes.map((s) => ({
    id: s.id,
    // eslint-disable-next-line no-underscore-dangle
    shouldBeDestroyed: Boolean(s._destroy),
    environmentScope: s.environment_scope,
  }));

const mapStrategiesParametersToViewModel = (params) => {
  if (params.userIds) {
    return { ...params, userIds: params.userIds.split(',').join(', ') };
  }
  return params;
};

export const mapStrategiesToViewModel = (strategiesFromRails) =>
  (strategiesFromRails || []).map((s) => ({
    id: s.id,
    name: s.name,
    parameters: mapStrategiesParametersToViewModel(s.parameters),
    userList: s.user_list,
    // eslint-disable-next-line no-underscore-dangle
    shouldBeDestroyed: Boolean(s._destroy),
    scopes: mapStrategyScopesToView(s.scopes),
  }));

const mapStrategiesParametersToRails = (params) => {
  if (params.userIds) {
    return { ...params, userIds: params.userIds.replace(/\s*,\s*/g, ',') };
  }
  return params;
};

const mapStrategyToRails = (strategy) => {
  const mappedStrategy = {
    id: strategy.id,
    name: strategy.name,
    _destroy: strategy.shouldBeDestroyed,
    scopes_attributes: mapStrategyScopesToRails(strategy.scopes || []),
    parameters: mapStrategiesParametersToRails(strategy.parameters),
  };

  if (strategy.name === ROLLOUT_STRATEGY_GITLAB_USER_LIST) {
    mappedStrategy.user_list_id = strategy.userList.id;
  }
  return mappedStrategy;
};

export const mapStrategiesToRails = (params) => ({
  operations_feature_flag: {
    name: params.name,
    description: params.description,
    active: params.active,
    strategies_attributes: (params.strategies || []).map(mapStrategyToRails),
    version: NEW_VERSION_FLAG,
  },
});
