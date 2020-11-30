<script>
import { mapState, mapActions, mapGetters } from 'vuex';
import { GlButton, GlModalDirective } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import eventHub from '../event_hub';
import { integrationLevels } from '../constants';

import OverrideDropdown from './override_dropdown.vue';
import ActiveCheckbox from './active_checkbox.vue';
import JiraTriggerFields from './jira_trigger_fields.vue';
import JiraIssuesFields from './jira_issues_fields.vue';
import TriggerFields from './trigger_fields.vue';
import DynamicField from './dynamic_field.vue';
import ConfirmationModal from './confirmation_modal.vue';
import ResetConfirmationModal from './reset_confirmation_modal.vue';

export default {
  name: 'IntegrationForm',
  components: {
    OverrideDropdown,
    ActiveCheckbox,
    JiraTriggerFields,
    JiraIssuesFields,
    TriggerFields,
    DynamicField,
    ConfirmationModal,
    ResetConfirmationModal,
    GlButton,
  },
  directives: {
    'gl-modal': GlModalDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  computed: {
    ...mapGetters(['currentKey', 'propsSource', 'isDisabled']),
    ...mapState([
      'defaultState',
      'customState',
      'override',
      'isSaving',
      'isTesting',
      'isResetting',
    ]),
    isEditable() {
      return this.propsSource.editable;
    },
    isJira() {
      return this.propsSource.type === 'jira';
    },
    isInstanceOrGroupLevel() {
      return (
        this.customState.integrationLevel === integrationLevels.INSTANCE ||
        this.customState.integrationLevel === integrationLevels.GROUP
      );
    },
    showJiraIssuesFields() {
      return this.isJira && this.glFeatures.jiraIssuesIntegration;
    },
    showReset() {
      return this.isInstanceOrGroupLevel && this.propsSource.resetPath;
    },
  },
  methods: {
    ...mapActions(['setOverride', 'setIsSaving', 'setIsTesting', 'setIsResetting']),
    onSaveClick() {
      this.setIsSaving(true);
      eventHub.$emit('saveIntegration');
    },
    onTestClick() {
      this.setIsTesting(true);
      eventHub.$emit('testIntegration');
    },
    onResetClick() {},
  },
};
</script>

<template>
  <div>
    <override-dropdown
      v-if="defaultState !== null"
      :inherit-from-id="defaultState.id"
      :override="override"
      :learn-more-path="propsSource.learnMorePath"
      @change="setOverride"
    />
    <active-checkbox v-if="propsSource.showActive" :key="`${currentKey}-active-checkbox`" />
    <jira-trigger-fields
      v-if="isJira"
      :key="`${currentKey}-jira-trigger-fields`"
      v-bind="propsSource.triggerFieldsProps"
    />
    <trigger-fields
      v-else-if="propsSource.triggerEvents.length"
      :key="`${currentKey}-trigger-fields`"
      :events="propsSource.triggerEvents"
      :type="propsSource.type"
    />
    <dynamic-field
      v-for="field in propsSource.fields"
      :key="`${currentKey}-${field.name}`"
      v-bind="field"
    />
    <jira-issues-fields
      v-if="showJiraIssuesFields"
      :key="`${currentKey}-jira-issues-fields`"
      v-bind="propsSource.jiraIssuesProps"
    />
    <div v-if="isEditable" class="footer-block row-content-block">
      <template v-if="isInstanceOrGroupLevel">
        <gl-button
          v-gl-modal.confirmSaveIntegration
          category="primary"
          variant="success"
          :loading="isSaving"
          :disabled="isDisabled"
          data-qa-selector="save_changes_button"
        >
          {{ __('Save changes') }}
        </gl-button>
        <confirmation-modal @submit="onSaveClick" />
      </template>
      <gl-button
        v-else
        category="primary"
        variant="success"
        type="submit"
        :loading="isSaving"
        :disabled="isDisabled"
        data-qa-selector="save_changes_button"
        @click.prevent="onSaveClick"
      >
        {{ __('Save changes') }}
      </gl-button>

      <gl-button
        v-if="propsSource.canTest"
        :loading="isTesting"
        :disabled="isDisabled"
        :href="propsSource.testPath"
        @click.prevent="onTestClick"
      >
        {{ __('Test settings') }}
      </gl-button>

      <template v-if="showReset">
        <gl-button
          v-gl-modal.confirmResetIntegration
          category="secondary"
          variant="default"
          :loading="isResetting"
          :disabled="isDisabled"
          data-testid="reset-button"
        >
          {{ __('Reset') }}
        </gl-button>
        <reset-confirmation-modal @reset="onResetClick" />
      </template>

      <gl-button class="btn-cancel" :href="propsSource.cancelPath">{{ __('Cancel') }}</gl-button>
    </div>
  </div>
</template>
