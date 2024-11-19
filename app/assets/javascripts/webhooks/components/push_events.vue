<script>
import { GlFormCheckbox, GlFormRadio, GlFormRadioGroup, GlFormInput, GlSprintf } from '@gitlab/ui';
import {
  BRANCH_FILTER_ALL_BRANCHES,
  WILDCARD_CODE_STABLE,
  WILDCARD_CODE_PRODUCTION,
  REGEX_CODE,
  descriptionText,
} from '~/webhooks/constants';

export default {
  components: {
    GlFormCheckbox,
    GlFormRadio,
    GlFormRadioGroup,
    GlFormInput,
    GlSprintf,
  },
  inject: ['pushEvents', 'strategy', 'isNewHook', 'pushEventsBranchFilter'],
  data() {
    return {
      pushEventsData: !this.isNewHook && this.pushEvents,
      branchFilterStrategyData: this.isNewHook ? BRANCH_FILTER_ALL_BRANCHES : this.strategy,
      pushEventsBranchFilterData: this.pushEventsBranchFilter,
    };
  },
  WILDCARD_CODE_STABLE,
  WILDCARD_CODE_PRODUCTION,
  REGEX_CODE,
  descriptionText,
};
</script>

<template>
  <div>
    <gl-form-checkbox v-model="pushEventsData">{{ __('Push events') }}</gl-form-checkbox>
    <input type="hidden" :value="pushEventsData" name="hook[push_events]" />

    <div v-if="pushEventsData" class="gl-pl-6">
      <gl-form-radio-group v-model="branchFilterStrategyData" name="hook[branch_filter_strategy]">
        <gl-form-radio
          class="branch-filter-strategy-radio gl-mt-2"
          value="all_branches"
          data-testid="rule_all_branches"
        >
          <div>{{ __('All branches') }}</div>
        </gl-form-radio>

        <!-- wildcard -->
        <gl-form-radio
          class="branch-filter-strategy-radio gl-mt-2"
          value="wildcard"
          data-testid="rule_wildcard"
        >
          <div>
            {{ s__('Webhooks|Wildcard pattern') }}
          </div>
        </gl-form-radio>
        <div class="gl-ml-6">
          <gl-form-input
            v-if="branchFilterStrategyData === 'wildcard'"
            v-model="pushEventsBranchFilterData"
            name="hook[push_events_branch_filter]"
            data-testid="webhook_branch_filter_field"
          />
        </div>
        <p
          v-if="branchFilterStrategyData === 'wildcard'"
          class="form-text custom-control gl-text-subtle"
        >
          <gl-sprintf :message="$options.descriptionText.wildcard">
            <template #WILDCARD_CODE_STABLE>
              <code>{{ $options.WILDCARD_CODE_STABLE }}</code>
            </template>
            <template #WILDCARD_CODE_PRODUCTION>
              <code>{{ $options.WILDCARD_CODE_PRODUCTION }}</code>
            </template>
          </gl-sprintf>
        </p>

        <!-- regex -->
        <gl-form-radio
          class="branch-filter-strategy-radio gl-mt-2"
          value="regex"
          data-testid="rule_regex"
        >
          <div>
            {{ s__('Webhooks|Regular expression') }}
          </div>
        </gl-form-radio>
        <div class="gl-ml-6">
          <gl-form-input
            v-if="branchFilterStrategyData === 'regex'"
            v-model="pushEventsBranchFilterData"
            name="hook[push_events_branch_filter]"
            data-testid="webhook_branch_filter_field"
          />
        </div>

        <p
          v-if="branchFilterStrategyData === 'regex'"
          class="form-text custom-control gl-text-subtle"
        >
          <gl-sprintf :message="$options.descriptionText.regex">
            <template #REGEX_CODE>
              <code>{{ $options.REGEX_CODE }}</code>
            </template>
          </gl-sprintf>
        </p>
      </gl-form-radio-group>
    </div>
  </div>
</template>
