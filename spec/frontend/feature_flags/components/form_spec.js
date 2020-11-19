import { uniqueId } from 'lodash';
import { shallowMount } from '@vue/test-utils';
import { GlFormTextarea, GlFormCheckbox, GlButton } from '@gitlab/ui';
import Api from '~/api';
import Form from '~/feature_flags/components/form.vue';
import EnvironmentsDropdown from '~/feature_flags/components/environments_dropdown.vue';
import Strategy from '~/feature_flags/components/strategy.vue';
import {
  ROLLOUT_STRATEGY_ALL_USERS,
  ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
  INTERNAL_ID_PREFIX,
  DEFAULT_PERCENT_ROLLOUT,
  LEGACY_FLAG,
  NEW_VERSION_FLAG,
} from '~/feature_flags/constants';
import RelatedIssuesRoot from '~/related_issues/components/related_issues_root.vue';
import ToggleButton from '~/vue_shared/components/toggle_button.vue';
import { featureFlag, userList, allUsersStrategy } from '../mock_data';

jest.mock('~/api.js');

describe('feature flag form', () => {
  let wrapper;
  const requiredProps = {
    cancelPath: 'feature_flags',
    submitText: 'Create',
  };

  const requiredInjections = {
    environmentsEndpoint: '/environments.json',
    projectId: '1',
    glFeatures: {
      featureFlagPermissions: true,
      featureFlagsNewVersion: true,
    },
  };

  const factory = (props = {}, provide = {}) => {
    wrapper = shallowMount(Form, {
      propsData: { ...requiredProps, ...props },
      provide: {
        ...requiredInjections,
        ...provide,
      },
    });
  };

  beforeEach(() => {
    Api.fetchFeatureFlagUserLists.mockResolvedValue({ data: [] });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render provided submitText', () => {
    factory(requiredProps);

    expect(wrapper.find('.js-ff-submit').text()).toEqual(requiredProps.submitText);
  });

  it('should render provided cancelPath', () => {
    factory(requiredProps);

    expect(wrapper.find('.js-ff-cancel').attributes('href')).toEqual(requiredProps.cancelPath);
  });

  it('does not render the related issues widget without the featureFlagIssuesEndpoint', () => {
    factory(requiredProps);

    expect(wrapper.find(RelatedIssuesRoot).exists()).toBe(false);
  });

  it('renders the related issues widget when the featureFlagIssuesEndpoint is provided', () => {
    factory(
      {},
      {
        ...requiredInjections,
        featureFlagIssuesEndpoint: '/some/endpoint',
      },
    );

    expect(wrapper.find(RelatedIssuesRoot).exists()).toBe(true);
  });

  describe('without provided data', () => {
    beforeEach(() => {
      factory(requiredProps);
    });

    it('should render name input text', () => {
      expect(wrapper.find('#feature-flag-name').exists()).toBe(true);
    });

    it('should render description textarea', () => {
      expect(wrapper.find('#feature-flag-description').exists()).toBe(true);
    });

    describe('scopes', () => {
      it('should render scopes table', () => {
        expect(wrapper.find('.js-scopes-table').exists()).toBe(true);
      });

      it('should render scopes table with a new row ', () => {
        expect(wrapper.find('.js-add-new-scope').exists()).toBe(true);
      });

      describe('status toggle', () => {
        describe('without filled text input', () => {
          it('should add a new scope with the text value empty and the status', () => {
            wrapper.find(ToggleButton).vm.$emit('change', true);

            expect(wrapper.vm.formScopes).toHaveLength(1);
            expect(wrapper.vm.formScopes[0].active).toEqual(true);
            expect(wrapper.vm.formScopes[0].environmentScope).toEqual('');

            expect(wrapper.vm.newScope).toEqual('');
          });
        });

        it('should be disabled if the feature flag is not active', done => {
          wrapper.setProps({ active: false });
          wrapper.vm.$nextTick(() => {
            expect(wrapper.find(ToggleButton).props('disabledInput')).toBe(true);
            done();
          });
        });
      });
    });
  });

  describe('with provided data', () => {
    beforeEach(() => {
      factory({
        ...requiredProps,
        name: featureFlag.name,
        description: featureFlag.description,
        active: true,
        version: LEGACY_FLAG,
        scopes: [
          {
            id: 1,
            active: true,
            environmentScope: 'scope',
            canUpdate: true,
            protected: false,
            rolloutStrategy: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
            rolloutPercentage: '54',
            rolloutUserIds: '123',
            shouldIncludeUserIds: true,
          },
          {
            id: 2,
            active: true,
            environmentScope: 'scope',
            canUpdate: false,
            protected: true,
            rolloutStrategy: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
            rolloutPercentage: '54',
            rolloutUserIds: '123',
            shouldIncludeUserIds: true,
          },
        ],
      });
    });

    describe('scopes', () => {
      it('should be possible to remove a scope', () => {
        expect(wrapper.find('.js-feature-flag-delete').exists()).toEqual(true);
      });

      it('renders empty row to add a new scope', () => {
        expect(wrapper.find('.js-add-new-scope').exists()).toEqual(true);
      });

      it('renders the user id checkbox', () => {
        expect(wrapper.find(GlFormCheckbox).exists()).toBe(true);
      });

      it('renders the user id text area', () => {
        expect(wrapper.find(GlFormTextarea).exists()).toBe(true);

        expect(wrapper.find(GlFormTextarea).vm.value).toBe('123');
      });

      describe('update scope', () => {
        describe('on click on toggle', () => {
          it('should update the scope', () => {
            wrapper.find(ToggleButton).vm.$emit('change', false);

            expect(wrapper.vm.formScopes[0].active).toBe(false);
          });

          it('should be disabled if the feature flag is not active', done => {
            wrapper.setProps({ active: false });

            wrapper.vm.$nextTick(() => {
              expect(wrapper.find(ToggleButton).props('disabledInput')).toBe(true);
              done();
            });
          });
        });
        describe('on strategy change', () => {
          it('should not include user IDs if All Users is selected', () => {
            const scope = wrapper.find({ ref: 'scopeRow' });
            scope.find('select').setValue(ROLLOUT_STRATEGY_ALL_USERS);
            return wrapper.vm.$nextTick().then(() => {
              expect(scope.find('#rollout-user-id-0').exists()).toBe(false);
            });
          });
        });
      });

      describe('deleting an existing scope', () => {
        beforeEach(() => {
          wrapper.find('.js-delete-scope').vm.$emit('click');
        });

        it('should add `shouldBeDestroyed` key the clicked scope', () => {
          expect(wrapper.vm.formScopes[0].shouldBeDestroyed).toBe(true);
        });

        it('should not render deleted scopes', () => {
          expect(wrapper.vm.filteredScopes).toEqual([expect.objectContaining({ id: 2 })]);
        });
      });

      describe('deleting a new scope', () => {
        it('should remove the scope from formScopes', () => {
          factory({
            ...requiredProps,
            name: 'feature_flag_1',
            description: 'this is a feature flag',
            scopes: [
              {
                environmentScope: 'new_scope',
                active: false,
                id: uniqueId(INTERNAL_ID_PREFIX),
                canUpdate: true,
                protected: false,
                strategies: [
                  {
                    name: ROLLOUT_STRATEGY_ALL_USERS,
                    parameters: {},
                  },
                ],
              },
            ],
          });

          wrapper.find('.js-delete-scope').vm.$emit('click');

          expect(wrapper.vm.formScopes).toEqual([]);
        });
      });

      describe('with * scope', () => {
        beforeEach(() => {
          factory({
            ...requiredProps,
            name: 'feature_flag_1',
            description: 'this is a feature flag',
            scopes: [
              {
                environmentScope: '*',
                active: false,
                canUpdate: false,
                rolloutStrategy: ROLLOUT_STRATEGY_ALL_USERS,
                rolloutPercentage: DEFAULT_PERCENT_ROLLOUT,
              },
            ],
          });
        });

        it('renders read only name', () => {
          expect(wrapper.find('.js-scope-all').exists()).toEqual(true);
        });
      });

      describe('without permission to update', () => {
        it('should have the flag name input disabled', () => {
          const input = wrapper.find('#feature-flag-name');

          expect(input.element.disabled).toBe(true);
        });

        it('should have the flag discription text area disabled', () => {
          const textarea = wrapper.find('#feature-flag-description');

          expect(textarea.element.disabled).toBe(true);
        });

        it('should have the scope that cannot be updated be disabled', () => {
          const row = wrapper.findAll('.gl-responsive-table-row').at(2);

          expect(row.find(EnvironmentsDropdown).vm.disabled).toBe(true);
          expect(row.find(ToggleButton).vm.disabledInput).toBe(true);
          expect(row.find('.js-delete-scope').exists()).toBe(false);
        });
      });
    });

    describe('on submit', () => {
      const selectFirstRolloutStrategyOption = dropdownIndex => {
        wrapper
          .findAll('select.js-rollout-strategy')
          .at(dropdownIndex)
          .findAll('option')
          .at(1)
          .setSelected();
      };

      beforeEach(() => {
        factory({
          ...requiredProps,
          name: 'feature_flag_1',
          active: true,
          description: 'this is a feature flag',
          scopes: [
            {
              id: 1,
              environmentScope: 'production',
              canUpdate: true,
              protected: true,
              active: false,
              rolloutStrategy: ROLLOUT_STRATEGY_ALL_USERS,
              rolloutPercentage: DEFAULT_PERCENT_ROLLOUT,
              rolloutUserIds: '',
            },
          ],
        });

        return wrapper.vm.$nextTick();
      });

      it('should emit handleSubmit with the updated data', () => {
        wrapper.find('#feature-flag-name').setValue('feature_flag_2');

        return wrapper.vm
          .$nextTick()
          .then(() => {
            wrapper
              .find('.js-new-scope-name')
              .find(EnvironmentsDropdown)
              .vm.$emit('selectEnvironment', 'review');

            return wrapper.vm.$nextTick();
          })
          .then(() => {
            wrapper
              .find('.js-add-new-scope')
              .find(ToggleButton)
              .vm.$emit('change', true);
          })
          .then(() => {
            wrapper.find(ToggleButton).vm.$emit('change', true);
            return wrapper.vm.$nextTick();
          })

          .then(() => {
            selectFirstRolloutStrategyOption(0);
            return wrapper.vm.$nextTick();
          })
          .then(() => {
            selectFirstRolloutStrategyOption(2);
            return wrapper.vm.$nextTick();
          })
          .then(() => {
            wrapper.find('.js-rollout-percentage').setValue('55');

            return wrapper.vm.$nextTick();
          })
          .then(() => {
            wrapper.find({ ref: 'submitButton' }).vm.$emit('click');

            const data = wrapper.emitted().handleSubmit[0][0];

            expect(data.name).toEqual('feature_flag_2');
            expect(data.description).toEqual('this is a feature flag');
            expect(data.active).toBe(true);

            expect(data.scopes).toEqual([
              {
                id: 1,
                active: true,
                environmentScope: 'production',
                canUpdate: true,
                protected: true,
                rolloutStrategy: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
                rolloutPercentage: '55',
                rolloutUserIds: '',
                shouldIncludeUserIds: false,
              },
              {
                id: expect.any(String),
                active: false,
                environmentScope: 'review',
                canUpdate: true,
                protected: false,
                rolloutStrategy: ROLLOUT_STRATEGY_ALL_USERS,
                rolloutPercentage: DEFAULT_PERCENT_ROLLOUT,
                rolloutUserIds: '',
              },
              {
                id: expect.any(String),
                active: true,
                environmentScope: '',
                canUpdate: true,
                protected: false,
                rolloutStrategy: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
                rolloutPercentage: DEFAULT_PERCENT_ROLLOUT,
                rolloutUserIds: '',
                shouldIncludeUserIds: false,
              },
            ]);
          });
      });
    });
  });

  describe('with strategies', () => {
    beforeEach(() => {
      Api.fetchFeatureFlagUserLists.mockResolvedValue({ data: [userList] });
      factory({
        ...requiredProps,
        name: featureFlag.name,
        description: featureFlag.description,
        active: true,
        version: NEW_VERSION_FLAG,
        strategies: [
          {
            type: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
            parameters: { percentage: '30' },
            scopes: [],
          },
          {
            type: ROLLOUT_STRATEGY_ALL_USERS,
            parameters: {},
            scopes: [{ environment_scope: 'review/*' }],
          },
        ],
      });
    });

    it('should show the strategy component', () => {
      const strategy = wrapper.find(Strategy);
      expect(strategy.exists()).toBe(true);
      expect(strategy.props('strategy')).toEqual({
        type: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
        parameters: { percentage: '30' },
        scopes: [],
      });
    });

    it('should show one strategy component per strategy', () => {
      expect(wrapper.findAll(Strategy)).toHaveLength(2);
    });

    it('adds an all users strategy when clicking the Add button', () => {
      wrapper.find(GlButton).vm.$emit('click');

      return wrapper.vm.$nextTick().then(() => {
        const strategies = wrapper.findAll(Strategy);

        expect(strategies).toHaveLength(3);
        expect(strategies.at(2).props('strategy')).toEqual(allUsersStrategy);
      });
    });

    it('should remove a strategy on delete', () => {
      const strategy = {
        type: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
        parameters: { percentage: '30' },
        scopes: [],
      };
      wrapper.find(Strategy).vm.$emit('delete');
      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.findAll(Strategy)).toHaveLength(1);
        expect(wrapper.find(Strategy).props('strategy')).not.toEqual(strategy);
      });
    });
  });
});
