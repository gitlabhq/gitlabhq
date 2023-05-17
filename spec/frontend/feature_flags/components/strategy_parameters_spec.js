import { shallowMount } from '@vue/test-utils';
import { last } from 'lodash';
import Default from '~/feature_flags/components/strategies/default.vue';
import GitlabUserList from '~/feature_flags/components/strategies/gitlab_user_list.vue';
import PercentRollout from '~/feature_flags/components/strategies/percent_rollout.vue';
import UsersWithId from '~/feature_flags/components/strategies/users_with_id.vue';
import StrategyParameters from '~/feature_flags/components/strategy_parameters.vue';
import {
  ROLLOUT_STRATEGY_ALL_USERS,
  ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
  ROLLOUT_STRATEGY_USER_ID,
  ROLLOUT_STRATEGY_GITLAB_USER_LIST,
} from '~/feature_flags/constants';
import { allUsersStrategy } from '../mock_data';

const DEFAULT_PROPS = {
  strategy: allUsersStrategy,
};

describe('~/feature_flags/components/strategy_parameters.vue', () => {
  let wrapper;

  const factory = (props = {}) =>
    shallowMount(StrategyParameters, {
      propsData: {
        ...DEFAULT_PROPS,
        ...props,
      },
    });

  describe.each`
    name                                 | component
    ${ROLLOUT_STRATEGY_ALL_USERS}        | ${Default}
    ${ROLLOUT_STRATEGY_PERCENT_ROLLOUT}  | ${PercentRollout}
    ${ROLLOUT_STRATEGY_USER_ID}          | ${UsersWithId}
    ${ROLLOUT_STRATEGY_GITLAB_USER_LIST} | ${GitlabUserList}
  `('with $name', ({ name, component }) => {
    let strategy;

    beforeEach(() => {
      strategy = { name, parameters: {} };
      wrapper = factory({ strategy });
    });

    it('should show the correct component', () => {
      expect(wrapper.findComponent(component).exists()).toBe(true);
    });

    it('should emit changes from the lower component', () => {
      const strategyParameterWrapper = wrapper.findComponent(component);

      strategyParameterWrapper.vm.$emit('change', { parameters: { foo: 'bar' } });

      expect(last(wrapper.emitted('change'))).toEqual([
        {
          name,
          parameters: { foo: 'bar' },
        },
      ]);
    });
  });

  describe('pass through props', () => {
    it('should pass through any extra props that might be needed', () => {
      const strategy = {
        name: ROLLOUT_STRATEGY_USER_ID,
      };
      wrapper = factory({
        strategy,
      });

      expect(wrapper.findComponent(UsersWithId).props('strategy')).toEqual(strategy);
    });
  });
});
