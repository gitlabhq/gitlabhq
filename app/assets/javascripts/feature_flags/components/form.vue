<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlButton } from '@gitlab/ui';
import { memoize, cloneDeep, isNumber, uniqueId } from 'lodash';
import { s__ } from '~/locale';
import RelatedIssuesRoot from '~/related_issues/components/related_issues_root.vue';
import featureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  ROLLOUT_STRATEGY_ALL_USERS,
  ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
  ROLLOUT_STRATEGY_USER_ID,
  ALL_ENVIRONMENTS_NAME,
  NEW_VERSION_FLAG,
} from '../constants';
import Strategy from './strategy.vue';

export default {
  i18n: {
    removeLabel: s__('FeatureFlags|Remove'),
    statusLabel: s__('FeatureFlags|Status'),
  },
  components: {
    GlButton,
    Strategy,
    RelatedIssuesRoot,
  },
  mixins: [featureFlagsMixin()],
  inject: {
    featureFlagIssuesEndpoint: {
      default: '',
    },
  },
  props: {
    active: {
      type: Boolean,
      required: false,
      default: true,
    },
    name: {
      type: String,
      required: false,
      default: '',
    },
    description: {
      type: String,
      required: false,
      default: '',
    },
    cancelPath: {
      type: String,
      required: true,
    },
    submitText: {
      type: String,
      required: true,
    },
    strategies: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  translations: {
    allEnvironmentsText: s__('FeatureFlags|* (All Environments)'),

    helpText: s__(
      'FeatureFlags|Feature Flag behavior is built up by creating a set of rules to define the status of target environments. A default wildcard rule %{codeStart}*%{codeEnd} for %{boldStart}All Environments%{boldEnd} is set, and you are able to add as many rules as you need by choosing environment specs below. You can toggle the behavior for each of your rules to set them %{boldStart}Active%{boldEnd} or %{boldStart}Inactive%{boldEnd}.',
    ),

    newHelpText: s__(
      'FeatureFlags|Enable features for specific users and environments by configuring feature flag strategies.',
    ),
    noStrategiesText: s__('FeatureFlags|Feature Flag has no strategies'),
  },

  ROLLOUT_STRATEGY_ALL_USERS,
  ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
  ROLLOUT_STRATEGY_USER_ID,

  // Matches numbers 0 through 100
  rolloutPercentageRegex: /^[0-9]$|^[1-9][0-9]$|^100$/,

  data() {
    return {
      formName: this.name,
      formDescription: this.description,

      formStrategies: cloneDeep(this.strategies),

      newScope: '',
    };
  },
  computed: {
    filteredStrategies() {
      return this.formStrategies.filter((s) => !s.shouldBeDestroyed);
    },
    showRelatedIssues() {
      return Boolean(this.featureFlagIssuesEndpoint);
    },
  },
  methods: {
    keyFor(strategy) {
      if (strategy.id) {
        return strategy.id;
      }

      return uniqueId('strategy_');
    },

    addStrategy() {
      this.formStrategies.push({ name: ROLLOUT_STRATEGY_ALL_USERS, parameters: {}, scopes: [] });
    },

    deleteStrategy(s) {
      if (isNumber(s.id)) {
        Object.assign(s, { shouldBeDestroyed: true });
      } else {
        this.formStrategies = this.formStrategies.filter((strategy) => strategy !== s);
      }
    },

    isAllEnvironment(name) {
      return name === ALL_ENVIRONMENTS_NAME;
    },
    /**
     * When the user clicks the submit button
     * it triggers an event with the form data
     */
    handleSubmit() {
      const flag = {
        name: this.formName,
        description: this.formDescription,
        active: this.active,
        version: NEW_VERSION_FLAG,
        strategies: this.formStrategies,
      };

      this.$emit('handleSubmit', flag);
    },

    isRolloutPercentageInvalid: memoize(function isRolloutPercentageInvalid(percentage) {
      return !this.$options.rolloutPercentageRegex.test(percentage);
    }),
    onFormStrategyChange(strategy, index) {
      const currentUserListId = this.filteredStrategies[index]?.userList?.id;
      const newUserListId = strategy?.userList?.id;

      Object.assign(this.filteredStrategies[index], strategy);

      if (currentUserListId !== newUserListId) {
        this.formStrategies = [...this.formStrategies];
      }
    },
  },
};
</script>
<template>
  <form class="feature-flags-form">
    <fieldset>
      <div class="-gl-mx-5 gl-flex gl-flex-wrap">
        <div class="gl-mb-5 gl-w-full gl-px-5 md:gl-basis-1/3">
          <label for="feature-flag-name" class="gl-font-bold"
            >{{ s__('FeatureFlags|Name') }} *</label
          >
          <input id="feature-flag-name" v-model="formName" class="form-control" />
        </div>
      </div>

      <div class="-gl-mx-5 gl-flex gl-flex-wrap">
        <div class="gl-mb-5 gl-w-full gl-px-5 md:gl-basis-1/3">
          <label for="feature-flag-description" class="gl-font-bold">
            {{ s__('FeatureFlags|Description') }}
          </label>
          <textarea
            id="feature-flag-description"
            v-model="formDescription"
            class="form-control"
            rows="4"
          ></textarea>
        </div>
      </div>

      <related-issues-root
        v-if="showRelatedIssues"
        :endpoint="featureFlagIssuesEndpoint"
        :can-admin="true"
        :show-categorized-issues="false"
      />

      <div class="-gl-mx-5 gl-flex gl-flex-wrap">
        <div class="gl-mb-5 gl-w-full gl-px-5">
          <h4>{{ s__('FeatureFlags|Strategies') }}</h4>
          <div class="gl-flex gl-items-baseline gl-justify-between">
            <p class="gl-mr-5">{{ $options.translations.newHelpText }}</p>
            <gl-button variant="confirm" category="secondary" @click="addStrategy">
              {{ s__('FeatureFlags|Add strategy') }}
            </gl-button>
          </div>
        </div>
      </div>
      <div v-if="filteredStrategies.length > 0" data-testid="feature-flag-strategies">
        <strategy
          v-for="(strategy, index) in filteredStrategies"
          :key="keyFor(strategy)"
          :strategy="strategy"
          :index="index"
          @change="onFormStrategyChange($event, index)"
          @delete="deleteStrategy(strategy)"
        />
      </div>
      <div v-else class="gl-border-t gl-flex gl-w-full gl-justify-center gl-py-6">
        <span>{{ $options.translations.noStrategiesText }}</span>
      </div>
    </fieldset>

    <div class="gl-mr-6">
      <gl-button
        ref="submitButton"
        type="button"
        variant="confirm"
        class="js-ff-submit gl-mr-2"
        @click="handleSubmit"
        >{{ submitText }}</gl-button
      >
      <gl-button :href="cancelPath" class="js-ff-cancel">
        {{ __('Cancel') }}
      </gl-button>
    </div>
  </form>
</template>
