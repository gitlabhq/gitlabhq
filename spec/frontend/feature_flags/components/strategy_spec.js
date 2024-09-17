import { GlAlert, GlFormSelect, GlLink, GlToken, GlButton, GlFormGroup } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import { last } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import Api from '~/api';
import axios from '~/lib/utils/axios_utils';
import NewEnvironmentsDropdown from '~/feature_flags/components/new_environments_dropdown.vue';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import Strategy from '~/feature_flags/components/strategy.vue';
import StrategyParameters from '~/feature_flags/components/strategy_parameters.vue';
import {
  PERCENT_ROLLOUT_GROUP_ID,
  ROLLOUT_STRATEGY_ALL_USERS,
  ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
  ROLLOUT_STRATEGY_FLEXIBLE_ROLLOUT,
  ROLLOUT_STRATEGY_USER_ID,
  ROLLOUT_STRATEGY_GITLAB_USER_LIST,
} from '~/feature_flags/constants';
import createStore from '~/feature_flags/store/new';

import { userList } from '../mock_data';

jest.mock('~/api');

const TEST_HOST = '/test';
const provide = {
  strategyTypeDocsPagePath: 'link-to-strategy-docs',
  environmentsScopeDocsPath: 'link-scope-docs',
  environmentsEndpoint: TEST_HOST,
};

Vue.use(Vuex);

describe('Feature flags strategy', () => {
  let wrapper;
  let axiosMock;

  const findStrategyParameters = () => wrapper.findComponent(StrategyParameters);
  const findDocsLinks = () => wrapper.findAllComponents(GlLink);
  const findToken = () => wrapper.findComponent(GlToken);

  const factory = (
    opts = {
      propsData: {
        strategy: {},
        index: 0,
      },
      provide,
    },
  ) => {
    axiosMock = new MockAdapter(axios);
    axiosMock.onGet(TEST_HOST).reply(HTTP_STATUS_OK, []);
    wrapper = shallowMount(Strategy, { store: createStore({ projectId: '1' }), ...opts });
  };

  beforeEach(() => {
    Api.searchFeatureFlagUserLists.mockResolvedValue({ data: [userList] });
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('helper links', () => {
    const propsData = { strategy: {}, index: 0, userLists: [userList] };
    factory({ propsData, provide, stubs: { GlFormGroup } });

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

    beforeEach(async () => {
      strategy = { name, parameters: {}, scopes: [] };
      propsData = { strategy, index: 0 };
      factory({ propsData, provide });
      await nextTick();
    });

    it('should set the select to match the strategy name', () => {
      expect(wrapper.findComponent(GlFormSelect).attributes('value')).toBe(name);
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
      expect(wrapper.findComponent(GlAlert).text()).toContain(
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

      it('should revert to all-environments scope when last scope is removed', async () => {
        const token = findToken();
        token.vm.$emit('close');
        await nextTick();
        expect(wrapper.findAllComponents(GlToken)).toHaveLength(0);
        expect(last(wrapper.emitted('change'))).toEqual([
          {
            name: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
            parameters: { percentage: '50', groupId: PERCENT_ROLLOUT_GROUP_ID },
            scopes: [{ environmentScope: '*' }],
          },
        ]);
      });
    });

    describe('with a single environment scope defined and existing feature flag', () => {
      let strategy;
      beforeEach(() => {
        strategy = {
          name: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
          parameters: { percentage: '50', groupId: 'default' },
          scopes: [{ environmentScope: 'production', id: 1 }],
        };
        const propsData = { strategy, index: 0 };
        factory({ propsData, provide });
      });

      it('should revert single environment scope when last scope is removed', async () => {
        findToken().vm.$emit('close');
        await nextTick();

        expect(wrapper.emitted('change')).toEqual([
          [
            {
              name: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
              parameters: { percentage: '50', groupId: PERCENT_ROLLOUT_GROUP_ID },
              scopes: [{ environmentScope: 'production', id: 1, shouldBeDestroyed: true }],
            },
          ],
        ]);
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

      it('should change the parameters if a different strategy is chosen', async () => {
        const select = wrapper.findComponent(GlFormSelect);
        select.vm.$emit('change', ROLLOUT_STRATEGY_ALL_USERS);
        await nextTick();
        expect(last(wrapper.emitted('change'))).toEqual([
          {
            name: ROLLOUT_STRATEGY_ALL_USERS,
            parameters: {},
            scopes: [{ environmentScope: '*' }],
          },
        ]);
      });

      it('should display selected scopes', async () => {
        const dropdown = wrapper.findComponent(NewEnvironmentsDropdown);
        dropdown.vm.$emit('add', 'production');
        await nextTick();
        expect(wrapper.findAllComponents(GlToken)).toHaveLength(1);
        expect(findToken().text()).toBe('production');
      });

      it('should display all selected scopes', async () => {
        const dropdown = wrapper.findComponent(NewEnvironmentsDropdown);
        dropdown.vm.$emit('add', 'production');
        dropdown.vm.$emit('add', 'staging');
        await nextTick();
        const tokens = wrapper.findAllComponents(GlToken);
        expect(tokens).toHaveLength(2);
        expect(tokens.at(0).text()).toBe('production');
        expect(tokens.at(1).text()).toBe('staging');
      });

      it('should emit selected scopes', async () => {
        const dropdown = wrapper.findComponent(NewEnvironmentsDropdown);
        dropdown.vm.$emit('add', 'production');
        await nextTick();
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

      it('should emit a delete if the delete button is clicked', () => {
        wrapper.findComponent(GlButton).vm.$emit('click');
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

      it('should display selected scopes', async () => {
        const dropdown = wrapper.findComponent(NewEnvironmentsDropdown);
        dropdown.vm.$emit('add', 'production');
        await nextTick();
        expect(wrapper.findAllComponents(GlToken)).toHaveLength(1);
        expect(findToken().text()).toBe('production');
      });

      it('should display all selected scopes', async () => {
        const dropdown = wrapper.findComponent(NewEnvironmentsDropdown);
        dropdown.vm.$emit('add', 'production');
        dropdown.vm.$emit('add', 'staging');
        await nextTick();
        const tokens = wrapper.findAllComponents(GlToken);
        expect(tokens).toHaveLength(2);
        expect(tokens.at(0).text()).toBe('production');
        expect(tokens.at(1).text()).toBe('staging');
      });

      it('should emit selected scopes', async () => {
        const dropdown = wrapper.findComponent(NewEnvironmentsDropdown);
        dropdown.vm.$emit('add', 'production');
        await nextTick();
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
