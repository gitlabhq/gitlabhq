<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlAlert, GlButton, GlFormSelect, GlFormGroup, GlLink, GlToken } from '@gitlab/ui';
import { isNumber } from 'lodash';
import { s__, __ } from '~/locale';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
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
    GlLink,
    GlToken,
    NewEnvironmentsDropdown,
    StrategyParameters,
    HelpIcon,
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
        // eslint-disable-next-line no-param-reassign
        environment.shouldBeDestroyed = true;
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

    <div class="gl-border-t-1 gl-border-t-default gl-py-6 gl-border-t-solid">
      <div class="gl-flex gl-flex-col @md/panel:gl-flex-row @md/panel:!gl-flex-wrap">
        <div class="!gl-mr-7">
          <gl-form-group :label="$options.i18n.strategyTypeLabel" :label-for="strategyTypeId">
            <template #description>
              {{ $options.i18n.strategyTypeDescription }}
              <gl-link :href="strategyTypeDocsPagePath" target="_blank">
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
        </div>

        <div data-testid="strategy">
          <strategy-parameters
            :strategy="strategy"
            :user-lists="userLists"
            @change="onStrategyChange"
          />
        </div>

        <div
          class="order-first gl-offset-md-0 gl-order-md-0 gl-ml-auto !gl-self-end @md/panel:!gl-self-stretch"
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

      <label class="gl-block" :for="environmentsDropdownId">{{
        $options.i18n.environmentsLabel
      }}</label>
      <div class="gl-flex gl-flex-col">
        <div class="gl-flex gl-flex-col @md/panel:gl-flex-row @md/panel:gl-items-center">
          <new-environments-dropdown
            :id="environmentsDropdownId"
            class="gl-mr-3"
            @add="addEnvironment"
          />
          <span
            v-if="appliesToAllEnvironments"
            class="gl-mt-3 gl-text-subtle @md/panel:!gl-ml-5 @md/panel:!gl-mt-0"
          >
            {{ $options.i18n.allEnvironments }}
          </span>
          <div v-else class="gl-flex gl-flex-wrap gl-items-center">
            <gl-token
              v-for="environment in filteredEnvironments"
              :key="environment.id"
              class="rounded-pill gl-mb-3 gl-mr-3 gl-mt-3 @md/panel:!gl-ml-3 @md/panel:!gl-mr-0 @md/panel:!gl-mt-0"
              @close="removeScope(environment)"
            >
              {{ environment.environmentScope }}
            </gl-token>
          </div>
        </div>
      </div>
      <span class="gl-inline-block gl-py-3">
        {{ $options.i18n.environmentsSelectDescription }}
      </span>
      <gl-link :href="environmentsScopeDocsPath" target="_blank">
        <help-icon />
      </gl-link>
    </div>
  </div>
</template>
