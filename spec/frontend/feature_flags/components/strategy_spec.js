import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { last } from 'lodash';
import { GlAlert, GlFormSelect, GlLink, GlToken, GlButton } from '@gitlab/ui';
import Api from '~/api';
import createStore from '~/feature_flags/store/new';
import {
  PERCENT_ROLLOUT_GROUP_ID,
  ROLLOUT_STRATEGY_ALL_USERS,
  ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
  ROLLOUT_STRATEGY_FLEXIBLE_ROLLOUT,
  ROLLOUT_STRATEGY_USER_ID,
  ROLLOUT_STRATEGY_GITLAB_USER_LIST,
} from '~/feature_flags/constants';
import Strategy from '~/feature_flags/components/strategy.vue';
import NewEnvironmentsDropdown from '~/feature_flags/components/new_environments_dropdown.vue';
import StrategyParameters from '~/feature_flags/components/strategy_parameters.vue';

import { userList } from '../mock_data';

jest.mock('~/api');

const provide = {
  strategyTypeDocsPagePath: 'link-to-strategy-docs',
  environmentsScopeDocsPath: 'link-scope-docs',
  environmentsEndpoint: '',
};

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Feature flags strategy', () => {
  let wrapper;

  const findStrategyParameters = () => wrapper.find(StrategyParameters);
  const findDocsLinks = () => wrapper.findAll(GlLink);

  const factory = (
    opts = {
      propsData: {
        strategy: {},
        index: 0,
      },
      provide,
    },
  ) => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
    wrapper = mount(Strategy, { localVue, store: createStore({ projectId: '1' }), ...opts });
  };

  beforeEach(() => {
    Api.searchFeatureFlagUserLists.mockResolvedValue({ data: [userList] });
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  describe('helper links', () => {
    const propsData = { strategy: {}, index: 0, userLists: [userList] };
    factory({ propsData, provide });

    it('should display 2 helper links', () => {
      const links = findDocsLinks();
      expect(links.exists()).toBe(true);
      expect(links.at(0).attributes('href')).toContain('docs');
      expect(links.at(1).attributes('href')).toContain('docs');
    });
  });

  describe.each`
    name
    ${ROLLOUT_STRATEGY_ALL_USERS}
    ${ROLLOUT_STRATEGY_PERCENT_ROLLOUT}
    ${ROLLOUT_STRATEGY_FLEXIBLE_ROLLOUT}
    ${ROLLOUT_STRATEGY_USER_ID}
    ${ROLLOUT_STRATEGY_GITLAB_USER_LIST}
  `('with strategy $name', ({ name }) => {
    let propsData;
    let strategy;

    beforeEach(() => {
      strategy = { name, parameters: {}, scopes: [] };
      propsData = { strategy, index: 0 };
      factory({ propsData, provide });
      return wrapper.vm.$nextTick();
    });

    it('should set the select to match the strategy name', () => {
      expect(wrapper.find(GlFormSelect).element.value).toBe(name);
    });

    it('should emit a change if the parameters component does', () => {
      findStrategyParameters().vm.$emit('change', { name, parameters: { test: 'parameters' } });
      expect(last(wrapper.emitted('change'))).toEqual([
        { name, parameters: { test: 'parameters' } },
      ]);
    });
  });

  describe('with the gradualRolloutByUserId strategy', () => {
    let strategy;

    beforeEach(() => {
      strategy = {
        name: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
        parameters: { percentage: '50', groupId: 'default' },
        scopes: [{ environmentScope: 'production' }],
      };
      const propsData = { strategy, index: 0 };
      factory({ propsData, provide });
    });

    it('shows an alert asking users to consider using flexibleRollout instead', () => {
      expect(wrapper.find(GlAlert).text()).toContain(
        'Consider using the more flexible "Percent rollout" strategy instead.',
      );
    });
  });

  describe('with a strategy', () => {
    describe('with a single environment scope defined', () => {
      let strategy;

      beforeEach(() => {
        strategy = {
          name: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
          parameters: { percentage: '50', groupId: 'default' },
          scopes: [{ environmentScope: 'production' }],
        };
        const propsData = { strategy, index: 0 };
        factory({ propsData, provide });
      });

      it('should revert to all-environments scope when last scope is removed', () => {
        const token = wrapper.find(GlToken);
        token.vm.$emit('close');
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.findAll(GlToken)).toHaveLength(0);
          expect(last(wrapper.emitted('change'))).toEqual([
            {
              name: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
              parameters: { percentage: '50', groupId: PERCENT_ROLLOUT_GROUP_ID },
              scopes: [{ environmentScope: '*' }],
            },
          ]);
        });
      });
    });

    describe('with an all-environments scope defined', () => {
      let strategy;

      beforeEach(() => {
        strategy = {
          name: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
          parameters: { percentage: '50', groupId: PERCENT_ROLLOUT_GROUP_ID },
          scopes: [{ environmentScope: '*' }],
        };
        const propsData = { strategy, index: 0 };
        factory({ propsData, provide });
      });

      it('should change the parameters if a different strategy is chosen', () => {
        const select = wrapper.find(GlFormSelect);
        select.setValue(ROLLOUT_STRATEGY_ALL_USERS);
        return wrapper.vm.$nextTick().then(() => {
          expect(last(wrapper.emitted('change'))).toEqual([
            {
              name: ROLLOUT_STRATEGY_ALL_USERS,
              parameters: {},
              scopes: [{ environmentScope: '*' }],
            },
          ]);
        });
      });

      it('should display selected scopes', () => {
        const dropdown = wrapper.find(NewEnvironmentsDropdown);
        dropdown.vm.$emit('add', 'production');
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.findAll(GlToken)).toHaveLength(1);
          expect(wrapper.find(GlToken).text()).toBe('production');
        });
      });

      it('should display all selected scopes', () => {
        const dropdown = wrapper.find(NewEnvironmentsDropdown);
        dropdown.vm.$emit('add', 'production');
        dropdown.vm.$emit('add', 'staging');
        return wrapper.vm.$nextTick().then(() => {
          const tokens = wrapper.findAll(GlToken);
          expect(tokens).toHaveLength(2);
          expect(tokens.at(0).text()).toBe('production');
          expect(tokens.at(1).text()).toBe('staging');
        });
      });

      it('should emit selected scopes', () => {
        const dropdown = wrapper.find(NewEnvironmentsDropdown);
        dropdown.vm.$emit('add', 'production');
        return wrapper.vm.$nextTick().then(() => {
          expect(last(wrapper.emitted('change'))).toEqual([
            {
              name: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
              parameters: { percentage: '50', groupId: PERCENT_ROLLOUT_GROUP_ID },
              scopes: [
                { environmentScope: '*', shouldBeDestroyed: true },
                { environmentScope: 'production' },
              ],
            },
          ]);
        });
      });

      it('should emit a delete if the delete button is clicked', () => {
        wrapper.find(GlButton).vm.$emit('click');
        expect(wrapper.emitted('delete')).toEqual([[]]);
      });
    });

    describe('without scopes defined', () => {
      beforeEach(() => {
        const strategy = {
          name: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
          parameters: { percentage: '50', groupId: PERCENT_ROLLOUT_GROUP_ID },
          scopes: [],
        };
        const propsData = { strategy, index: 0 };
        factory({ propsData, provide });
      });

      it('should display selected scopes', () => {
        const dropdown = wrapper.find(NewEnvironmentsDropdown);
        dropdown.vm.$emit('add', 'production');
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.findAll(GlToken)).toHaveLength(1);
          expect(wrapper.find(GlToken).text()).toBe('production');
        });
      });

      it('should display all selected scopes', () => {
        const dropdown = wrapper.find(NewEnvironmentsDropdown);
        dropdown.vm.$emit('add', 'production');
        dropdown.vm.$emit('add', 'staging');
        return wrapper.vm.$nextTick().then(() => {
          const tokens = wrapper.findAll(GlToken);
          expect(tokens).toHaveLength(2);
          expect(tokens.at(0).text()).toBe('production');
          expect(tokens.at(1).text()).toBe('staging');
        });
      });

      it('should emit selected scopes', () => {
        const dropdown = wrapper.find(NewEnvironmentsDropdown);
        dropdown.vm.$emit('add', 'production');
        return wrapper.vm.$nextTick().then(() => {
          expect(last(wrapper.emitted('change'))).toEqual([
            {
              name: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
              parameters: { percentage: '50', groupId: PERCENT_ROLLOUT_GROUP_ID },
              scopes: [{ environmentScope: 'production' }],
            },
          ]);
        });
      });
    });
  });
});
