import { shallowMount } from '@vue/test-utils';
import { GlFormSelect, GlFormTextarea, GlFormInput, GlLink, GlToken, GlButton } from '@gitlab/ui';
import {
  PERCENT_ROLLOUT_GROUP_ID,
  ROLLOUT_STRATEGY_ALL_USERS,
  ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
  ROLLOUT_STRATEGY_USER_ID,
  ROLLOUT_STRATEGY_GITLAB_USER_LIST,
} from '~/feature_flags/constants';
import Strategy from '~/feature_flags/components/strategy.vue';
import NewEnvironmentsDropdown from '~/feature_flags/components/new_environments_dropdown.vue';

import { userList } from '../mock_data';

const provide = {
  strategyTypeDocsPagePath: 'link-to-strategy-docs',
  environmentsScopeDocsPath: 'link-scope-docs',
};

describe('Feature flags strategy', () => {
  let wrapper;

  const findStrategy = () => wrapper.find('[data-testid="strategy"]');
  const findDocsLinks = () => wrapper.findAll(GlLink);

  const factory = (
    opts = {
      propsData: {
        strategy: {},
        index: 0,
        endpoint: '',
        userLists: [userList],
      },
      provide,
    },
  ) => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
    wrapper = shallowMount(Strategy, opts);
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  describe('helper links', () => {
    const propsData = { strategy: {}, index: 0, endpoint: '', userLists: [userList] };
    factory({ propsData, provide });

    it('should display 2 helper links', () => {
      const links = findDocsLinks();
      expect(links.exists()).toBe(true);
      expect(links.at(0).attributes('href')).toContain('docs');
      expect(links.at(1).attributes('href')).toContain('docs');
    });
  });

  describe.each`
    name                                | parameter       | value    | newValue   | input
    ${ROLLOUT_STRATEGY_ALL_USERS}       | ${null}         | ${null}  | ${null}    | ${null}
    ${ROLLOUT_STRATEGY_PERCENT_ROLLOUT} | ${'percentage'} | ${'50'}  | ${'20'}    | ${GlFormInput}
    ${ROLLOUT_STRATEGY_USER_ID}         | ${'userIds'}    | ${'1,2'} | ${'1,2,3'} | ${GlFormTextarea}
  `('with strategy $name', ({ name, parameter, value, newValue, input }) => {
    let propsData;
    let strategy;
    beforeEach(() => {
      const parameters = {};
      if (parameter !== null) {
        parameters[parameter] = value;
      }
      strategy = { name, parameters };
      propsData = { strategy, index: 0, endpoint: '' };
      factory({ propsData, provide });
    });

    it('should set the select to match the strategy name', () => {
      expect(wrapper.find(GlFormSelect).attributes('value')).toBe(name);
    });

    it('should not show inputs for other parameters', () => {
      [GlFormTextarea, GlFormInput, GlFormSelect]
        .filter(component => component !== input)
        .map(component => findStrategy().findAll(component))
        .forEach(inputWrapper => expect(inputWrapper).toHaveLength(0));
    });

    if (parameter !== null) {
      it(`should show the input for ${parameter} with the correct value`, () => {
        const inputWrapper = findStrategy().find(input);
        expect(inputWrapper.exists()).toBe(true);
        expect(inputWrapper.attributes('value')).toBe(value);
      });

      it(`should emit a change event when altering ${parameter}`, () => {
        const inputWrapper = findStrategy().find(input);
        inputWrapper.vm.$emit('input', newValue);
        expect(wrapper.emitted('change')).toEqual([
          [{ name, parameters: expect.objectContaining({ [parameter]: newValue }), scopes: [] }],
        ]);
      });
    }
  });

  describe('with strategy gitlabUserList', () => {
    let propsData;
    let strategy;
    beforeEach(() => {
      strategy = { name: ROLLOUT_STRATEGY_GITLAB_USER_LIST, userListId: '2', parameters: {} };
      propsData = { strategy, index: 0, endpoint: '', userLists: [userList] };
      factory({ propsData, provide });
    });

    it('should set the select to match the strategy name', () => {
      expect(wrapper.find(GlFormSelect).attributes('value')).toBe(
        ROLLOUT_STRATEGY_GITLAB_USER_LIST,
      );
    });

    it('should not show inputs for other parameters', () => {
      expect(
        findStrategy()
          .find(GlFormTextarea)
          .exists(),
      ).toBe(false);
      expect(
        findStrategy()
          .find(GlFormInput)
          .exists(),
      ).toBe(false);
    });

    it('should show the input for userListId with the correct value', () => {
      const inputWrapper = findStrategy().find(GlFormSelect);
      expect(inputWrapper.exists()).toBe(true);
      expect(inputWrapper.attributes('value')).toBe('2');
    });

    it('should emit a change event when altering the userListId', () => {
      const inputWrapper = findStrategy().find(GlFormSelect);
      inputWrapper.vm.$emit('input', '3');
      inputWrapper.vm.$emit('change', '3');
      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.emitted('change')).toEqual([
          [
            {
              name: ROLLOUT_STRATEGY_GITLAB_USER_LIST,
              userListId: '3',
              scopes: [],
              parameters: {},
            },
          ],
        ]);
      });
    });
  });

  describe('with a strategy', () => {
    describe('with a single environment scope defined', () => {
      let strategy;

      beforeEach(() => {
        strategy = {
          name: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
          parameters: { percentage: '50' },
          scopes: [{ environmentScope: 'production' }],
        };
        const propsData = { strategy, index: 0, endpoint: '' };
        factory({ propsData, provide });
      });

      it('should revert to all-environments scope when last scope is removed', () => {
        const token = wrapper.find(GlToken);
        token.vm.$emit('close');
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.findAll(GlToken)).toHaveLength(0);
          expect(wrapper.emitted('change')).toEqual([
            [
              {
                name: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
                parameters: { percentage: '50', groupId: PERCENT_ROLLOUT_GROUP_ID },
                scopes: [{ environmentScope: '*' }],
              },
            ],
          ]);
        });
      });
    });

    describe('with an all-environments scope defined', () => {
      let strategy;

      beforeEach(() => {
        strategy = {
          name: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
          parameters: { percentage: '50' },
          scopes: [{ environmentScope: '*' }],
        };
        const propsData = { strategy, index: 0, endpoint: '' };
        factory({ propsData, provide });
      });

      it('should change the parameters if a different strategy is chosen', () => {
        const select = wrapper.find(GlFormSelect);
        select.vm.$emit('input', ROLLOUT_STRATEGY_ALL_USERS);
        select.vm.$emit('change', ROLLOUT_STRATEGY_ALL_USERS);
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.find(GlFormInput).exists()).toBe(false);
          expect(wrapper.emitted('change')).toEqual([
            [
              {
                name: ROLLOUT_STRATEGY_ALL_USERS,
                parameters: {},
                scopes: [{ environmentScope: '*' }],
              },
            ],
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
          expect(wrapper.emitted('change')).toEqual([
            [
              {
                name: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
                parameters: { percentage: '50', groupId: PERCENT_ROLLOUT_GROUP_ID },
                scopes: [
                  { environmentScope: '*', shouldBeDestroyed: true },
                  { environmentScope: 'production' },
                ],
              },
            ],
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
          parameters: { percentage: '50' },
          scopes: [],
        };
        const propsData = { strategy, index: 0, endpoint: '' };
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
          expect(wrapper.emitted('change')).toEqual([
            [
              {
                name: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
                parameters: { percentage: '50', groupId: PERCENT_ROLLOUT_GROUP_ID },
                scopes: [{ environmentScope: 'production' }],
              },
            ],
          ]);
        });
      });
    });
  });
});
