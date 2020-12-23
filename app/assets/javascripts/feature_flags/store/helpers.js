import { isEmpty, uniqueId, isString } from 'lodash';
import {
  ROLLOUT_STRATEGY_ALL_USERS,
  ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
  ROLLOUT_STRATEGY_USER_ID,
  ROLLOUT_STRATEGY_GITLAB_USER_LIST,
  INTERNAL_ID_PREFIX,
  DEFAULT_PERCENT_ROLLOUT,
  PERCENT_ROLLOUT_GROUP_ID,
  fetchPercentageParams,
  fetchUserIdParams,
  LEGACY_FLAG,
} from '../constants';

/**
 * Converts raw scope objects fetched from the API into an array of scope
 * objects that is easier/nicer to bind to in Vue.
 * @param {Array} scopesFromRails An array of scope objects fetched from the API
 */
export const mapToScopesViewModel = (scopesFromRails) =>
  (scopesFromRails || []).map((s) => {
    const percentStrategy = (s.strategies || []).find(
      (strat) => strat.name === ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
    );

    const rolloutPercentage = fetchPercentageParams(percentStrategy) || DEFAULT_PERCENT_ROLLOUT;

    const userStrategy = (s.strategies || []).find(
      (strat) => strat.name === ROLLOUT_STRATEGY_USER_ID,
    );

    const rolloutStrategy =
      (percentStrategy && percentStrategy.name) ||
      (userStrategy && userStrategy.name) ||
      ROLLOUT_STRATEGY_ALL_USERS;

    const rolloutUserIds = (fetchUserIdParams(userStrategy) || '')
      .split(',')
      .filter((id) => id)
      .join(', ');

    return {
      id: s.id,
      environmentScope: s.environment_scope,
      active: Boolean(s.active),
      canUpdate: Boolean(s.can_update),
      protected: Boolean(s.protected),
      rolloutStrategy,
      rolloutPercentage,
      rolloutUserIds,

      // eslint-disable-next-line no-underscore-dangle
      shouldBeDestroyed: Boolean(s._destroy),
      shouldIncludeUserIds: rolloutUserIds.length > 0 && percentStrategy !== null,
    };
  });
/**
 * Converts the parameters emitted by the Vue component into
 * the shape that the Rails API expects.
 * @param {Array} scopesFromVue An array of scope objects from the Vue component
 */
export const mapFromScopesViewModel = (params) => {
  const scopes = (params.scopes || []).map((s) => {
    const parameters = {};
    if (s.rolloutStrategy === ROLLOUT_STRATEGY_PERCENT_ROLLOUT) {
      parameters.groupId = PERCENT_ROLLOUT_GROUP_ID;
      parameters.percentage = s.rolloutPercentage;
    } else if (s.rolloutStrategy === ROLLOUT_STRATEGY_USER_ID) {
      parameters.userIds = (s.rolloutUserIds || '').replace(/, /g, ',');
    }

    const userIdParameters = {};

    if (s.shouldIncludeUserIds && s.rolloutStrategy !== ROLLOUT_STRATEGY_USER_ID) {
      userIdParameters.userIds = (s.rolloutUserIds || '').replace(/, /g, ',');
    }

    // Strip out any internal IDs
    const id = isString(s.id) && s.id.startsWith(INTERNAL_ID_PREFIX) ? undefined : s.id;

    const strategies = [
      {
        name: s.rolloutStrategy,
        parameters,
      },
    ];

    if (!isEmpty(userIdParameters)) {
      strategies.push({ name: ROLLOUT_STRATEGY_USER_ID, parameters: userIdParameters });
    }

    return {
      id,
      environment_scope: s.environmentScope,
      active: s.active,
      can_update: s.canUpdate,
      protected: s.protected,
      _destroy: s.shouldBeDestroyed,
      strategies,
    };
  });

  const model = {
    operations_feature_flag: {
      name: params.name,
      description: params.description,
      active: params.active,
      scopes_attributes: scopes,
      version: LEGACY_FLAG,
    },
  };

  return model;
};

/**
 * Creates a new feature flag environment scope object for use
 * in a Vue component.  An optional parameter can be passed to
 * override the property values that are created by default.
 *
 * @param {Object} overrides An optional object whose
 * property values will be used to override the default values.
 *
 */
export const createNewEnvironmentScope = (overrides = {}, featureFlagPermissions = false) => {
  const defaultScope = {
    environmentScope: '',
    active: false,
    id: uniqueId(INTERNAL_ID_PREFIX),
    rolloutStrategy: ROLLOUT_STRATEGY_ALL_USERS,
    rolloutPercentage: DEFAULT_PERCENT_ROLLOUT,
    rolloutUserIds: '',
  };

  const newScope = {
    ...defaultScope,
    ...overrides,
  };

  if (featureFlagPermissions) {
    newScope.canUpdate = true;
    newScope.protected = false;
  }

  return newScope;
};

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
    version: params.version,
    active: params.active,
    strategies_attributes: (params.strategies || []).map(mapStrategyToRails),
  },
});
