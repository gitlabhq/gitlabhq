<script>
import { GlAlert, GlButton, GlFormSelect, GlFormGroup, GlIcon, GlLink } from '@gitlab/ui';
import { isNumber, uniqueId } from 'lodash';
import Vue from 'vue';
import { s__, __ } from '~/locale';
import {
  EMPTY_PARAMETERS,
  STRATEGY_SELECTIONS,
  ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
  ALL_ENVIRONMENTS_NAME,
} from '../constants';

import NewEnvironmentsDropdown from './new_environments_dropdown.vue';
import StrategyParameters from './strategy_parameters.vue';

export default {
  components: {
    GlAlert,
    GlButton,
    GlFormGroup,
    GlFormSelect,
    GlIcon,
    GlLink,
    NewEnvironmentsDropdown,
    StrategyParameters,
  },
  inject: {
    strategyTypeDocsPagePath: {
      default: '',
    },
    environmentsScopeDocsPath: {
      default: '',
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
    userLists: {
      type: Array,
      required: false,
      default: () => [],
    },
  },

  i18n: {
    allEnvironments: __('All environments'),
    environmentsLabel: __('Environments'),
    strategyTypeDescription: __('Select strategy activation method'),
    strategyTypeLabel: s__('FeatureFlag|Type'),
    environmentsSelectDescription: s__(
      'FeatureFlag|Select the environment scope for this feature flag',
    ),
    considerFlexibleRollout: s__(
      'FeatureFlags|Consider using the more flexible "Percent rollout" strategy instead.',
    ),
  },

  strategies: STRATEGY_SELECTIONS,

  data() {
    return {
      environments: this.strategy.scopes || [],
      formStrategy: { ...this.strategy },
    };
  },
  computed: {
    strategyTypeId() {
      return `strategy-type-${this.index}`;
    },
    environmentsDropdownId() {
      return `environments-dropdown-${this.index}`;
    },
    appliesToAllEnvironments() {
      return (
        this.filteredEnvironments.length === 1 &&
        this.filteredEnvironments[0].environmentScope === ALL_ENVIRONMENTS_NAME
      );
    },
    filteredEnvironments() {
      return this.environments.filter((e) => !e.shouldBeDestroyed);
    },
    selectableEnvironments() {
      return this.environments.filter(
        (e) => !e.shouldBeDestroyed && e.environmentScope !== ALL_ENVIRONMENTS_NAME,
      );
    },
    filteredEnvironmentsOptions() {
      return this.selectableEnvironments.map(({ id, environmentScope: name }) => ({
        id: id || uniqueId('env_'),
        name,
      }));
    },
    isPercentUserRollout() {
      return this.formStrategy.name === ROLLOUT_STRATEGY_PERCENT_ROLLOUT;
    },
  },
  methods: {
    addEnvironment(environment) {
      const allEnvironmentsScope = this.environments.find(
        (scope) => scope.environmentScope === ALL_ENVIRONMENTS_NAME,
      );
      if (allEnvironmentsScope) {
        allEnvironmentsScope.shouldBeDestroyed = true;
      }

      const foundEnv = this.environments.find(
        ({ environmentScope }) => environmentScope === environment,
      );
      if (isNumber(foundEnv?.id)) {
        Vue.set(foundEnv, 'shouldBeDestroyed', false);
      } else {
        this.environments.push({ environmentScope: environment });
      }

      this.onStrategyChange({ ...this.formStrategy, scopes: this.environments });
    },
    onStrategyTypeChange(name) {
      this.onStrategyChange({
        ...this.formStrategy,
        ...EMPTY_PARAMETERS,
        name,
      });
    },
    onStrategyChange(s) {
      this.$emit('change', s);
      this.formStrategy = s;
    },
    removeScope(target) {
      const environment = this.environments.find(
        ({ environmentScope }) => environmentScope === target,
      );

      if (isNumber(environment?.id)) {
        Vue.set(environment, 'shouldBeDestroyed', true);
      } else {
        this.environments = this.environments.filter((e) => e.environmentScope !== target);
      }
      if (this.filteredEnvironments.length === 0) {
        this.environments.push({ environmentScope: '*' });
      }
      this.onStrategyChange({ ...this.formStrategy, scopes: this.environments });
    },
  },
};
</script>
<template>
  <div>
    <gl-alert v-if="isPercentUserRollout" variant="tip" :dismissible="false">
      {{ $options.i18n.considerFlexibleRollout }}
    </gl-alert>

    <div class="gl-border-t-solid gl-border-t-1 gl-border-t-gray-100 gl-py-6">
      <div class="gl-display-flex gl-flex-direction-column gl-md-flex-direction-row flex-md-wrap">
        <div class="gl-mr-7">
          <gl-form-group :label="$options.i18n.strategyTypeLabel" :label-for="strategyTypeId">
            <template #description>
              {{ $options.i18n.strategyTypeDescription }}
              <gl-link :href="strategyTypeDocsPagePath" target="_blank">
                <gl-icon name="question" />
              </gl-link>
            </template>
            <gl-form-select
              :id="strategyTypeId"
              :value="formStrategy.name"
              :options="$options.strategies"
              @change="onStrategyTypeChange"
            />
          </gl-form-group>
        </div>

        <div data-testid="strategy">
          <strategy-parameters
            :strategy="strategy"
            :user-lists="userLists"
            @change="onStrategyChange"
          />
        </div>

        <div
          class="align-self-end align-self-md-stretch order-first offset-md-0 order-md-0 gl-ml-auto"
        >
          <gl-button
            data-testid="delete-strategy-button"
            variant="danger"
            icon="remove"
            :aria-label="__('Delete')"
            @click="$emit('delete')"
          />
        </div>
      </div>

      <gl-form-group :label="$options.i18n.environmentsLabel" :label-for="environmentsDropdownId">
        <div class="row">
          <div class="gl-display-flex gl-flex-direction-column gl-md-flex-direction-row gl-w-full">
            <div class="gl-w-full gl-md-w-auto col-md-4">
              <new-environments-dropdown
                :id="environmentsDropdownId"
                :selected="filteredEnvironmentsOptions"
                @remove="removeScope"
                @add="addEnvironment"
              />
            </div>
            <span
              v-if="appliesToAllEnvironments"
              class="gl-flex-gl-text-secondary gl-mt-2 gl-pl-5 gl-md-pl-0"
            >
              {{ $options.i18n.allEnvironments }}
            </span>
          </div>
        </div>
        <template #description>
          {{ $options.i18n.environmentsSelectDescription }}
          <gl-link :href="environmentsScopeDocsPath" target="_blank">
            <gl-icon name="question" />
          </gl-link>
        </template>
      </gl-form-group>
    </div>
  </div>
</template>
