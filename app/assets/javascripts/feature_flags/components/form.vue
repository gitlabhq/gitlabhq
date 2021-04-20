<script>
import {
  GlButton,
  GlBadge,
  GlTooltip,
  GlTooltipDirective,
  GlFormTextarea,
  GlFormCheckbox,
  GlSprintf,
  GlIcon,
  GlToggle,
} from '@gitlab/ui';
import { memoize, isString, cloneDeep, isNumber, uniqueId } from 'lodash';
import Vue from 'vue';
import { s__ } from '~/locale';
import RelatedIssuesRoot from '~/related_issues/components/related_issues_root.vue';
import featureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  ROLLOUT_STRATEGY_ALL_USERS,
  ROLLOUT_STRATEGY_PERCENT_ROLLOUT,
  ROLLOUT_STRATEGY_USER_ID,
  ALL_ENVIRONMENTS_NAME,
  INTERNAL_ID_PREFIX,
  NEW_VERSION_FLAG,
  LEGACY_FLAG,
} from '../constants';
import { createNewEnvironmentScope } from '../store/helpers';
import EnvironmentsDropdown from './environments_dropdown.vue';
import Strategy from './strategy.vue';

export default {
  i18n: {
    removeLabel: s__('FeatureFlags|Remove'),
    statusLabel: s__('FeatureFlags|Status'),
  },
  components: {
    GlButton,
    GlBadge,
    GlFormTextarea,
    GlFormCheckbox,
    GlTooltip,
    GlSprintf,
    GlIcon,
    GlToggle,
    EnvironmentsDropdown,
    Strategy,
    RelatedIssuesRoot,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
    scopes: {
      type: Array,
      required: false,
      default: () => [],
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
    version: {
      type: String,
      required: false,
      default: LEGACY_FLAG,
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

      // operate on a clone to avoid mutating props
      formScopes: this.scopes.map((s) => ({ ...s })),
      formStrategies: cloneDeep(this.strategies),

      newScope: '',
    };
  },
  computed: {
    filteredScopes() {
      return this.formScopes.filter((scope) => !scope.shouldBeDestroyed);
    },
    filteredStrategies() {
      return this.formStrategies.filter((s) => !s.shouldBeDestroyed);
    },
    canUpdateFlag() {
      return !this.permissionsFlag || (this.formScopes || []).every((scope) => scope.canUpdate);
    },
    permissionsFlag() {
      return this.glFeatures.featureFlagPermissions;
    },
    supportsStrategies() {
      return this.version === NEW_VERSION_FLAG;
    },
    showRelatedIssues() {
      return this.featureFlagIssuesEndpoint.length > 0;
    },
    readOnly() {
      return this.version === LEGACY_FLAG;
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
        Vue.set(s, 'shouldBeDestroyed', true);
      } else {
        this.formStrategies = this.formStrategies.filter((strategy) => strategy !== s);
      }
    },

    isAllEnvironment(name) {
      return name === ALL_ENVIRONMENTS_NAME;
    },

    /**
     * When the user clicks the remove button we delete the scope
     *
     * If the scope has an ID, we need to add the `shouldBeDestroyed` flag.
     * If the scope does *not* have an ID, we can just remove it.
     *
     * This flag will be used when submitting the data to the backend
     * to determine which records to delete (via a "_destroy" property).
     *
     * @param {Object} scope
     */
    removeScope(scope) {
      if (isString(scope.id) && scope.id.startsWith(INTERNAL_ID_PREFIX)) {
        this.formScopes = this.formScopes.filter((s) => s !== scope);
      } else {
        Vue.set(scope, 'shouldBeDestroyed', true);
      }
    },

    /**
     * Creates a new scope and adds it to the list of scopes
     *
     * @param overrides An object whose properties will
     * be used override the default scope options
     */
    createNewScope(overrides) {
      this.formScopes.push(createNewEnvironmentScope(overrides, this.permissionsFlag));
      this.newScope = '';
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
        version: this.version,
      };

      if (this.version === LEGACY_FLAG) {
        flag.scopes = this.formScopes;
      } else {
        flag.strategies = this.formStrategies;
      }

      this.$emit('handleSubmit', flag);
    },

    canUpdateScope(scope) {
      return !this.permissionsFlag || scope.canUpdate;
    },

    isRolloutPercentageInvalid: memoize(function isRolloutPercentageInvalid(percentage) {
      return !this.$options.rolloutPercentageRegex.test(percentage);
    }),

    /**
     * Generates a unique ID for the strategy based on the v-for index
     *
     * @param index The index of the strategy
     */
    rolloutStrategyId(index) {
      return `rollout-strategy-${index}`;
    },

    /**
     * Generates a unique ID for the percentage based on the v-for index
     *
     * @param index The index of the percentage
     */
    rolloutPercentageId(index) {
      return `rollout-percentage-${index}`;
    },
    rolloutUserId(index) {
      return `rollout-user-id-${index}`;
    },

    shouldDisplayIncludeUserIds(scope) {
      return ![ROLLOUT_STRATEGY_ALL_USERS, ROLLOUT_STRATEGY_USER_ID].includes(
        scope.rolloutStrategy,
      );
    },
    shouldDisplayUserIds(scope) {
      return scope.rolloutStrategy === ROLLOUT_STRATEGY_USER_ID || scope.shouldIncludeUserIds;
    },
    onStrategyChange(index) {
      const scope = this.filteredScopes[index];
      scope.shouldIncludeUserIds =
        scope.rolloutUserIds.length > 0 &&
        scope.rolloutStrategy === ROLLOUT_STRATEGY_PERCENT_ROLLOUT;
    },
    onFormStrategyChange(strategy, index) {
      Object.assign(this.filteredStrategies[index], strategy);
    },
  },
};
</script>
<template>
  <form class="feature-flags-form">
    <fieldset>
      <div class="row">
        <div class="form-group col-md-4">
          <label for="feature-flag-name" class="label-bold">{{ s__('FeatureFlags|Name') }} *</label>
          <input
            id="feature-flag-name"
            v-model="formName"
            :disabled="!canUpdateFlag"
            class="form-control"
          />
        </div>
      </div>

      <div class="row">
        <div class="form-group col-md-4">
          <label for="feature-flag-description" class="label-bold">
            {{ s__('FeatureFlags|Description') }}
          </label>
          <textarea
            id="feature-flag-description"
            v-model="formDescription"
            :disabled="!canUpdateFlag"
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

      <template v-if="supportsStrategies">
        <div class="row">
          <div class="col-md-12">
            <h4>{{ s__('FeatureFlags|Strategies') }}</h4>
            <div class="flex align-items-baseline justify-content-between">
              <p class="mr-3">{{ $options.translations.newHelpText }}</p>
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
        <div v-else class="flex justify-content-center border-top py-4 w-100">
          <span>{{ $options.translations.noStrategiesText }}</span>
        </div>
      </template>

      <div v-else class="row">
        <div class="form-group col-md-12">
          <h4>{{ s__('FeatureFlags|Target environments') }}</h4>
          <gl-sprintf :message="$options.translations.helpText">
            <template #code="{ content }">
              <code>{{ content }}</code>
            </template>
            <template #bold="{ content }">
              <b>{{ content }}</b>
            </template>
          </gl-sprintf>

          <div class="js-scopes-table gl-mt-3">
            <div class="gl-responsive-table-row table-row-header" role="row">
              <div class="table-section section-30" role="columnheader">
                {{ s__('FeatureFlags|Environment Spec') }}
              </div>
              <div class="table-section section-20 text-center" role="columnheader">
                {{ s__('FeatureFlags|Status') }}
              </div>
              <div class="table-section section-40" role="columnheader">
                {{ s__('FeatureFlags|Rollout Strategy') }}
              </div>
            </div>

            <div
              v-for="(scope, index) in filteredScopes"
              :key="scope.id"
              ref="scopeRow"
              class="gl-responsive-table-row"
              role="row"
            >
              <div class="table-section section-30" role="gridcell">
                <div class="table-mobile-header" role="rowheader">
                  {{ s__('FeatureFlags|Environment Spec') }}
                </div>
                <div
                  class="table-mobile-content gl-display-flex gl-align-items-center gl-justify-content-start"
                >
                  <p v-if="isAllEnvironment(scope.environmentScope)" class="js-scope-all pl-3">
                    {{ $options.translations.allEnvironmentsText }}
                  </p>

                  <environments-dropdown
                    v-else
                    class="col-12"
                    :value="scope.environmentScope"
                    :disabled="!canUpdateScope(scope) || scope.environmentScope !== ''"
                    @selectEnvironment="(env) => (scope.environmentScope = env)"
                    @createClicked="(env) => (scope.environmentScope = env)"
                    @clearInput="(env) => (scope.environmentScope = '')"
                  />

                  <gl-badge v-if="permissionsFlag && scope.protected" variant="success">
                    {{ s__('FeatureFlags|Protected') }}
                  </gl-badge>
                </div>
              </div>

              <div class="table-section section-20 text-center" role="gridcell">
                <div class="table-mobile-header" role="rowheader">
                  {{ $options.i18n.statusLabel }}
                </div>
                <div class="table-mobile-content gl-display-flex gl-justify-content-center">
                  <gl-toggle
                    :value="scope.active"
                    :disabled="!active || !canUpdateScope(scope)"
                    :label="$options.i18n.statusLabel"
                    label-position="hidden"
                    @change="(status) => (scope.active = status)"
                  />
                </div>
              </div>

              <div class="table-section section-40" role="gridcell">
                <div class="table-mobile-header" role="rowheader">
                  {{ s__('FeatureFlags|Rollout Strategy') }}
                </div>
                <div class="table-mobile-content js-rollout-strategy form-inline">
                  <label class="sr-only" :for="rolloutStrategyId(index)">
                    {{ s__('FeatureFlags|Rollout Strategy') }}
                  </label>
                  <div class="select-wrapper col-12 col-md-8 p-0">
                    <select
                      :id="rolloutStrategyId(index)"
                      v-model="scope.rolloutStrategy"
                      :disabled="!scope.active"
                      class="form-control select-control w-100 js-rollout-strategy"
                      @change="onStrategyChange(index)"
                    >
                      <option :value="$options.ROLLOUT_STRATEGY_ALL_USERS">
                        {{ s__('FeatureFlags|All users') }}
                      </option>
                      <option :value="$options.ROLLOUT_STRATEGY_PERCENT_ROLLOUT">
                        {{ s__('FeatureFlags|Percent rollout (logged in users)') }}
                      </option>
                      <option :value="$options.ROLLOUT_STRATEGY_USER_ID">
                        {{ s__('FeatureFlags|User IDs') }}
                      </option>
                    </select>
                    <gl-icon
                      name="chevron-down"
                      class="gl-absolute gl-top-3 gl-right-3 gl-text-gray-500"
                      :size="16"
                    />
                  </div>

                  <div
                    v-if="scope.rolloutStrategy === $options.ROLLOUT_STRATEGY_PERCENT_ROLLOUT"
                    class="d-flex-center mt-2 mt-md-0 ml-md-2"
                  >
                    <label class="sr-only" :for="rolloutPercentageId(index)">
                      {{ s__('FeatureFlags|Rollout Percentage') }}
                    </label>
                    <div class="gl-w-9">
                      <input
                        :id="rolloutPercentageId(index)"
                        v-model="scope.rolloutPercentage"
                        :disabled="!scope.active"
                        :class="{
                          'is-invalid': isRolloutPercentageInvalid(scope.rolloutPercentage),
                        }"
                        type="number"
                        min="0"
                        max="100"
                        :pattern="$options.rolloutPercentageRegex.source"
                        class="rollout-percentage js-rollout-percentage form-control text-right w-100"
                      />
                    </div>
                    <gl-tooltip
                      v-if="isRolloutPercentageInvalid(scope.rolloutPercentage)"
                      :target="rolloutPercentageId(index)"
                    >
                      {{
                        s__(
                          'FeatureFlags|Percent rollout must be an integer number between 0 and 100',
                        )
                      }}
                    </gl-tooltip>
                    <span class="ml-1">%</span>
                  </div>
                  <div class="d-flex flex-column align-items-start mt-2 w-100">
                    <gl-form-checkbox
                      v-if="shouldDisplayIncludeUserIds(scope)"
                      v-model="scope.shouldIncludeUserIds"
                      >{{ s__('FeatureFlags|Include additional user IDs') }}</gl-form-checkbox
                    >
                    <template v-if="shouldDisplayUserIds(scope)">
                      <label :for="rolloutUserId(index)" class="mb-2">
                        {{ s__('FeatureFlags|User IDs') }}
                      </label>
                      <gl-form-textarea
                        :id="rolloutUserId(index)"
                        v-model="scope.rolloutUserIds"
                        class="w-100"
                      />
                    </template>
                  </div>
                </div>
              </div>

              <div class="table-section section-10 text-right" role="gridcell">
                <div class="table-mobile-header" role="rowheader">
                  {{ s__('FeatureFlags|Remove') }}
                </div>
                <div class="table-mobile-content">
                  <gl-button
                    v-if="!isAllEnvironment(scope.environmentScope) && canUpdateScope(scope)"
                    v-gl-tooltip
                    :title="$options.i18n.removeLabel"
                    :aria-label="$options.i18n.removeLabel"
                    class="js-delete-scope btn-transparent pr-3 pl-3"
                    icon="clear"
                    data-testid="feature-flag-delete"
                    @click="removeScope(scope)"
                  />
                </div>
              </div>
            </div>

            <div class="gl-responsive-table-row" role="row" data-testid="add-new-scope">
              <div class="table-section section-30" role="gridcell">
                <div class="table-mobile-header" role="rowheader">
                  {{ s__('FeatureFlags|Environment Spec') }}
                </div>
                <div class="table-mobile-content">
                  <environments-dropdown
                    class="js-new-scope-name col-12"
                    :value="newScope"
                    @selectEnvironment="(env) => createNewScope({ environmentScope: env })"
                    @createClicked="(env) => createNewScope({ environmentScope: env })"
                  />
                </div>
              </div>

              <div class="table-section section-20 text-center" role="gridcell">
                <div class="table-mobile-header" role="rowheader">
                  {{ $options.i18n.statusLabel }}
                </div>
                <div class="table-mobile-content gl-display-flex gl-justify-content-center">
                  <gl-toggle
                    :disabled="!active"
                    :label="$options.i18n.statusLabel"
                    label-position="hidden"
                    :value="false"
                    @change="createNewScope({ active: true })"
                  />
                </div>
              </div>

              <div class="table-section section-40" role="gridcell">
                <div class="table-mobile-header" role="rowheader">
                  {{ s__('FeatureFlags|Rollout Strategy') }}
                </div>
                <div class="table-mobile-content js-rollout-strategy form-inline">
                  <label class="sr-only" for="new-rollout-strategy-placeholder">{{
                    s__('FeatureFlags|Rollout Strategy')
                  }}</label>
                  <div class="select-wrapper col-12 col-md-8 p-0">
                    <select
                      id="new-rollout-strategy-placeholder"
                      disabled
                      class="form-control select-control w-100"
                    >
                      <option>{{ s__('FeatureFlags|All users') }}</option>
                    </select>
                    <gl-icon
                      name="chevron-down"
                      class="gl-absolute gl-top-3 gl-right-3 gl-text-gray-500"
                      :size="16"
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </fieldset>

    <div class="form-actions">
      <gl-button
        ref="submitButton"
        :disabled="readOnly"
        type="button"
        variant="confirm"
        class="js-ff-submit col-xs-12"
        @click="handleSubmit"
        >{{ submitText }}</gl-button
      >
      <gl-button :href="cancelPath" class="js-ff-cancel col-xs-12 float-right">
        {{ __('Cancel') }}
      </gl-button>
    </div>
  </form>
</template>
