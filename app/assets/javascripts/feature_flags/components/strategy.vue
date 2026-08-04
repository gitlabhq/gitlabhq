<script>
import {
  GlAlert,
  GlButton,
  GlFormSelect,
  GlFormGroup,
  GlLink,
  GlToken,
  GlTooltipDirective,
} from '@gitlab/ui';
import { isNumber } from 'lodash-es';
import { s__, __ } from '~/locale';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import {
  ALL_ENVIRONMENTS_NAME,
  EMPTY_PARAMETERS,
  STRATEGY_SELECTIONS,
  ROLLOUT_STRATEGY_ALL_USERS,
  ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
} from '../constants';

import NewEnvironmentsDropdown from './new_environments_dropdown.vue';
import StrategyParameters from './strategy_parameters.vue';

export default {
  name: 'FeatureFlagsStrategy',
  components: {
    GlAlert,
    GlButton,
    GlFormGroup,
    GlFormSelect,
    GlLink,
    GlToken,
    NewEnvironmentsDropdown,
    StrategyParameters,
    HelpIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
  emits: ['change', 'delete'],

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
    selectedEnvironmentScopes() {
      return this.filteredEnvironments.map(({ environmentScope }) => environmentScope);
    },
    isPercentUserRollout() {
      return this.formStrategy.name === ROLLOUT_STRATEGY_PERCENT_ROLLOUT;
    },
    isDefaultStrategy() {
      return this.formStrategy.name === ROLLOUT_STRATEGY_ALL_USERS;
    },
  },
  methods: {
    addEnvironment(environment) {
      const existingScope = this.environments.find(
        (scope) => scope.environmentScope === environment,
      );

      if (existingScope && !existingScope.shouldBeDestroyed) {
        return;
      }

      if (environment !== ALL_ENVIRONMENTS_NAME) {
        // Adding a specific environment replaces the "All environments" (*) scope.
        this.environments
          .filter((scope) => scope.environmentScope === ALL_ENVIRONMENTS_NAME)
          .forEach((scope) => this.discardScope(scope));
      }

      if (existingScope) {
        this.environments = this.environments.map((scope) =>
          scope === existingScope ? { ...scope, shouldBeDestroyed: false } : scope,
        );
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
    // A persisted scope must be sent back marked for destruction; an unsaved
    // one can just be dropped.
    discardScope(scope) {
      this.environments = isNumber(scope.id)
        ? this.environments.map((s) => (s === scope ? { ...s, shouldBeDestroyed: true } : s))
        : this.environments.filter((s) => s !== scope);
    },
    removeScope(environment) {
      this.discardScope(environment);
      if (this.filteredEnvironments.length === 0) {
        const allEnvironmentsScope = this.environments.find(
          (scope) => scope.environmentScope === ALL_ENVIRONMENTS_NAME,
        );
        if (allEnvironmentsScope) {
          this.environments = this.environments.map((scope) =>
            scope === allEnvironmentsScope ? { ...scope, shouldBeDestroyed: false } : scope,
          );
        } else {
          this.environments.push({ environmentScope: ALL_ENVIRONMENTS_NAME });
        }
      }
      this.onStrategyChange({ ...this.formStrategy, scopes: this.environments });
    },
  },
};
</script>
<template>
  <div class="gl-border-b gl-mb-6 gl-flex gl-justify-between gl-gap-3 gl-pb-5">
    <div class="gl-flex gl-flex-col gl-gap-3">
      <gl-form-group :label="$options.i18n.strategyTypeLabel" :label-for="strategyTypeId">
        <template #description>
          {{ $options.i18n.strategyTypeDescription }}
          <gl-link
            :aria-label="s__('FeatureFlag|Feature flag strategy documentation')"
            :href="strategyTypeDocsPagePath"
            target="_blank"
          >
            <help-icon />
          </gl-link>
        </template>
        <gl-form-select
          :id="strategyTypeId"
          :value="formStrategy.name"
          :options="$options.strategies"
          @change="onStrategyTypeChange"
        />
      </gl-form-group>

      <gl-alert v-if="isPercentUserRollout" variant="tip" :dismissible="false">
        {{ $options.i18n.considerFlexibleRollout }}
      </gl-alert>

      <div v-if="!isDefaultStrategy" data-testid="strategy">
        <strategy-parameters
          :strategy="strategy"
          :user-lists="userLists"
          @change="onStrategyChange"
        />
      </div>

      <div class="gl-flex gl-flex-col gl-gap-2">
        <label class="gl-mb-0 gl-block" :for="environmentsDropdownId">{{
          $options.i18n.environmentsLabel
        }}</label>
        <div class="gl-flex gl-flex-col">
          <div class="gl-flex gl-flex-col @md/panel:gl-flex-row @md/panel:gl-items-center">
            <new-environments-dropdown
              :id="environmentsDropdownId"
              class="gl-mr-3"
              :excluded-environments="selectedEnvironmentScopes"
              @add="addEnvironment"
            />
            <span v-if="appliesToAllEnvironments" class="gl-text-subtle">
              {{ $options.i18n.allEnvironments }}
            </span>
            <div v-else class="gl-flex gl-flex-wrap gl-items-center gl-gap-2">
              <gl-token
                v-for="environment in filteredEnvironments"
                :key="environment.id"
                @close="removeScope(environment)"
              >
                {{ environment.environmentScope }}
              </gl-token>
            </div>
          </div>
        </div>
      </div>

      <div class="gl-flex gl-items-baseline gl-gap-2">
        <span class="gl-inline-block gl-py-3">
          {{ $options.i18n.environmentsSelectDescription }}
        </span>
        <gl-link
          :aria-label="s__('FeatureFlag|Feature flag environment documentation')"
          :href="environmentsScopeDocsPath"
          target="_blank"
        >
          <help-icon />
        </gl-link>
      </div>
    </div>

    <gl-button
      v-gl-tooltip
      class="gl-self-start"
      data-testid="delete-strategy-button"
      category="tertiary"
      icon="remove"
      :title="__('Remove')"
      :aria-label="__('Remove')"
      @click="$emit('delete')"
    />
  </div>
</template>
