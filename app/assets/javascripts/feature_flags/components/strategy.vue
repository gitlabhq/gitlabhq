<script>
import { GlAlert, GlButton, GlFormSelect, GlFormGroup, GlIcon, GlLink, GlToken } from '@gitlab/ui';
import { isNumber } from 'lodash';
import Vue from 'vue';
import { s__, __ } from '~/locale';
import {
  EMPTY_PARAMETERS,
  STRATEGY_SELECTIONS,
  ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
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
    GlToken,
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
        this.filteredEnvironments[0].environmentScope === '*'
      );
    },
    filteredEnvironments() {
      return this.environments.filter((e) => !e.shouldBeDestroyed);
    },
    isPercentUserRollout() {
      return this.formStrategy.name === ROLLOUT_STRATEGY_PERCENT_ROLLOUT;
    },
  },
  methods: {
    addEnvironment(environment) {
      const allEnvironmentsScope = this.environments.find(
        (scope) => scope.environmentScope === '*',
      );
      if (allEnvironmentsScope) {
        allEnvironmentsScope.shouldBeDestroyed = true;
      }
      this.environments.push({ environmentScope: environment });
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
    removeScope(environment) {
      if (isNumber(environment.id)) {
        Vue.set(environment, 'shouldBeDestroyed', true);
      } else {
        this.environments = this.environments.filter((e) => e !== environment);
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
        <div class="mr-5">
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

      <label class="gl-display-block" :for="environmentsDropdownId">{{
        $options.i18n.environmentsLabel
      }}</label>
      <div class="gl-display-flex gl-flex-direction-column">
        <div
          class="gl-display-flex gl-flex-direction-column gl-md-flex-direction-row align-items-start gl-md-align-items-center"
        >
          <new-environments-dropdown
            :id="environmentsDropdownId"
            class="gl-mr-3"
            @add="addEnvironment"
          />
          <span v-if="appliesToAllEnvironments" class="text-secondary gl-mt-3 mt-md-0 ml-md-3">
            {{ $options.i18n.allEnvironments }}
          </span>
          <div v-else class="gl-display-flex gl-align-items-center gl-flex-wrap">
            <gl-token
              v-for="environment in filteredEnvironments"
              :key="environment.id"
              class="gl-mt-3 gl-mr-3 gl-mb-3 mt-md-0 mr-md-0 ml-md-2 rounded-pill"
              @close="removeScope(environment)"
            >
              {{ environment.environmentScope }}
            </gl-token>
          </div>
        </div>
      </div>
      <span class="gl-display-inline-block gl-py-3">
        {{ $options.i18n.environmentsSelectDescription }}
      </span>
      <gl-link :href="environmentsScopeDocsPath" target="_blank">
        <gl-icon name="question" />
      </gl-link>
    </div>
  </div>
</template>
