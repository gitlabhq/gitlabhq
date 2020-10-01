<script>
import Vue from 'vue';
import { isNumber } from 'lodash';
import {
  GlButton,
  GlFormSelect,
  GlFormInput,
  GlFormTextarea,
  GlFormGroup,
  GlIcon,
  GlLink,
  GlToken,
} from '@gitlab/ui';
import { s__, __ } from '~/locale';
import {
  PERCENT_ROLLOUT_GROUP_ID,
  ROLLOUT_STRATEGY_ALL_USERS,
  ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
  ROLLOUT_STRATEGY_USER_ID,
  ROLLOUT_STRATEGY_GITLAB_USER_LIST,
} from '../constants';

import NewEnvironmentsDropdown from './new_environments_dropdown.vue';

export default {
  components: {
    GlButton,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    GlFormSelect,
    GlIcon,
    GlLink,
    GlToken,
    NewEnvironmentsDropdown,
  },
  model: {
    prop: 'strategy',
    event: 'change',
  },
  inject: {
    strategyTypeDocsPagePath: {
      type: String,
    },
    environmentsScopeDocsPath: {
      type: String,
    },
  },
  props: {
    strategy: {
      type: Object,
      required: true,
    },
    index: {
      type: Number,
      required: true,
    },
    endpoint: {
      type: String,
      required: false,
      default: '',
    },
    userLists: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  ROLLOUT_STRATEGY_ALL_USERS,
  ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
  ROLLOUT_STRATEGY_USER_ID,
  ROLLOUT_STRATEGY_GITLAB_USER_LIST,

  i18n: {
    allEnvironments: __('All environments'),
    environmentsLabel: __('Environments'),
    environmentsSelectDescription: __('Select the environment scope for this feature flag.'),
    rolloutPercentageDescription: __('Enter a whole number between 0 and 100'),
    rolloutPercentageInvalid: s__(
      'FeatureFlags|Percent rollout must be a whole number between 0 and 100',
    ),
    rolloutPercentageLabel: s__('FeatureFlag|Percentage'),
    rolloutUserIdsDescription: __('Enter one or more user ID separated by commas'),
    rolloutUserIdsLabel: s__('FeatureFlag|User IDs'),
    rolloutUserListLabel: s__('FeatureFlag|List'),
    rolloutUserListDescription: s__('FeatureFlag|Select a user list'),
    rolloutUserListNoListError: s__('FeatureFlag|There are no configured user lists'),
    strategyTypeDescription: __('Select strategy activation method.'),
    strategyTypeLabel: s__('FeatureFlag|Type'),
  },

  data() {
    return {
      environments: this.strategy.scopes || [],
      formStrategy: { ...this.strategy },
      formPercentage:
        this.strategy.name === ROLLOUT_STRATEGY_PERCENT_ROLLOUT
          ? this.strategy.parameters.percentage
          : '',
      formUserIds:
        this.strategy.name === ROLLOUT_STRATEGY_USER_ID ? this.strategy.parameters.userIds : '',
      formUserListId:
        this.strategy.name === ROLLOUT_STRATEGY_GITLAB_USER_LIST ? this.strategy.userListId : '',
      strategies: [
        {
          value: ROLLOUT_STRATEGY_ALL_USERS,
          text: __('All users'),
        },
        {
          value: ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
          text: __('Percent of users'),
        },
        {
          value: ROLLOUT_STRATEGY_USER_ID,
          text: __('User IDs'),
        },
        {
          value: ROLLOUT_STRATEGY_GITLAB_USER_LIST,
          text: __('User List'),
        },
      ],
    };
  },
  computed: {
    strategyTypeId() {
      return `strategy-type-${this.index}`;
    },
    strategyPercentageId() {
      return `strategy-percentage-${this.index}`;
    },
    strategyUserIdsId() {
      return `strategy-user-ids-${this.index}`;
    },
    strategyUserListId() {
      return `strategy-user-list-${this.index}`;
    },
    environmentsDropdownId() {
      return `environments-dropdown-${this.index}`;
    },
    isPercentRollout() {
      return this.isStrategyType(ROLLOUT_STRATEGY_PERCENT_ROLLOUT);
    },
    isUserWithId() {
      return this.isStrategyType(ROLLOUT_STRATEGY_USER_ID);
    },
    isUserList() {
      return this.isStrategyType(ROLLOUT_STRATEGY_GITLAB_USER_LIST);
    },
    appliesToAllEnvironments() {
      return (
        this.filteredEnvironments.length === 1 &&
        this.filteredEnvironments[0].environmentScope === '*'
      );
    },
    filteredEnvironments() {
      return this.environments.filter(e => !e.shouldBeDestroyed);
    },
    userListOptions() {
      return this.userLists.map(({ name, id }) => ({ value: id, text: name }));
    },
    hasUserLists() {
      return this.userListOptions.length > 0;
    },
  },
  methods: {
    addEnvironment(environment) {
      const allEnvironmentsScope = this.environments.find(scope => scope.environmentScope === '*');
      if (allEnvironmentsScope) {
        allEnvironmentsScope.shouldBeDestroyed = true;
      }
      this.environments.push({ environmentScope: environment });
      this.onStrategyChange();
    },
    onStrategyChange() {
      const parameters = {};
      const strategy = {
        ...this.formStrategy,
        scopes: this.environments,
      };
      switch (this.formStrategy.name) {
        case ROLLOUT_STRATEGY_PERCENT_ROLLOUT:
          parameters.percentage = this.formPercentage;
          parameters.groupId = PERCENT_ROLLOUT_GROUP_ID;
          break;
        case ROLLOUT_STRATEGY_USER_ID:
          parameters.userIds = this.formUserIds;
          break;
        case ROLLOUT_STRATEGY_GITLAB_USER_LIST:
          strategy.userListId = this.formUserListId;
          break;
        default:
          break;
      }
      this.$emit('change', {
        ...strategy,
        parameters,
      });
    },
    removeScope(environment) {
      if (isNumber(environment.id)) {
        Vue.set(environment, 'shouldBeDestroyed', true);
      } else {
        this.environments = this.environments.filter(e => e !== environment);
      }
      if (this.filteredEnvironments.length === 0) {
        this.environments.push({ environmentScope: '*' });
      }
      this.onStrategyChange();
    },
    isStrategyType(type) {
      return this.formStrategy.name === type;
    },
  },
};
</script>
<template>
  <div class="gl-border-t-solid gl-border-t-1 gl-border-t-gray-100 gl-py-6">
    <div class="gl-display-flex gl-flex-direction-column gl-md-flex-direction-row flex-md-wrap">
      <div class="mr-5">
        <gl-form-group :label="$options.i18n.strategyTypeLabel" :label-for="strategyTypeId">
          <p class="gl-display-inline-block ">{{ $options.i18n.strategyTypeDescription }}</p>
          <gl-link :href="strategyTypeDocsPagePath" target="_blank">
            <gl-icon name="question" />
          </gl-link>
          <gl-form-select
            :id="strategyTypeId"
            v-model="formStrategy.name"
            :options="strategies"
            @change="onStrategyChange"
          />
        </gl-form-group>
      </div>

      <div data-testid="strategy">
        <gl-form-group
          v-if="isPercentRollout"
          :label="$options.i18n.rolloutPercentageLabel"
          :description="$options.i18n.rolloutPercentageDescription"
          :label-for="strategyPercentageId"
          :invalid-feedback="$options.i18n.rolloutPercentageInvalid"
        >
          <div class="gl-display-flex gl-align-items-center">
            <gl-form-input
              :id="strategyPercentageId"
              v-model="formPercentage"
              class="rollout-percentage gl-text-right gl-w-9"
              type="number"
              @input="onStrategyChange"
            />
            <span class="gl-ml-2">%</span>
          </div>
        </gl-form-group>

        <gl-form-group
          v-if="isUserWithId"
          :label="$options.i18n.rolloutUserIdsLabel"
          :description="$options.i18n.rolloutUserIdsDescription"
          :label-for="strategyUserIdsId"
        >
          <gl-form-textarea
            :id="strategyUserIdsId"
            v-model="formUserIds"
            @input="onStrategyChange"
          />
        </gl-form-group>
        <gl-form-group
          v-if="isUserList"
          :state="hasUserLists"
          :invalid-feedback="$options.i18n.rolloutUserListNoListError"
          :label="$options.i18n.rolloutUserListLabel"
          :description="$options.i18n.rolloutUserListDescription"
          :label-for="strategyUserListId"
        >
          <gl-form-select
            :id="strategyUserListId"
            v-model="formUserListId"
            :options="userListOptions"
            @change="onStrategyChange"
          />
        </gl-form-group>
      </div>

      <div
        class="align-self-end align-self-md-stretch order-first offset-md-0 order-md-0 gl-ml-auto"
      >
        <gl-button
          data-testid="delete-strategy-button"
          variant="danger"
          icon="remove"
          @click="$emit('delete')"
        />
      </div>
    </div>
    <label class="gl-display-block" :for="environmentsDropdownId">{{
      $options.i18n.environmentsLabel
    }}</label>
    <p class="gl-display-inline-block">{{ $options.i18n.environmentsSelectDescription }}</p>
    <gl-link :href="environmentsScopeDocsPath" target="_blank">
      <gl-icon name="question" />
    </gl-link>
    <div class="gl-display-flex gl-flex-direction-column">
      <div
        class="gl-display-flex gl-flex-direction-column gl-md-flex-direction-row align-items-start gl-md-align-items-center"
      >
        <new-environments-dropdown
          :id="environmentsDropdownId"
          :endpoint="endpoint"
          class="gl-mr-3"
          @add="addEnvironment"
        />
        <span v-if="appliesToAllEnvironments" class="text-secondary gl-mt-3 mt-md-0 ml-md-3">
          {{ $options.i18n.allEnvironments }}
        </span>
        <div v-else class="gl-display-flex gl-align-items-center">
          <gl-token
            v-for="environment in filteredEnvironments"
            :key="environment.id"
            class="gl-mt-3 gl-mr-3 mt-md-0 mr-md-0 ml-md-2 rounded-pill"
            @close="removeScope(environment)"
          >
            {{ environment.environmentScope }}
          </gl-token>
        </div>
      </div>
    </div>
  </div>
</template>
