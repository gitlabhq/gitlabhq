<script>
import { GlToggle, GlAlert } from '@gitlab/ui';
import { sprintf } from '~/locale';
import { updateGroup } from '~/api/groups_api';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import {
  I18N_CONFIRM_MESSAGE,
  I18N_CONFIRM_OK,
  I18N_CONFIRM_CANCEL,
  I18N_CONFIRM_TITLE,
  I18N_UPDATE_ERROR_MESSAGE,
  I18N_REFRESH_MESSAGE,
} from '../constants';

export default {
  components: {
    GlToggle,
    GlAlert,
  },
  inject: [
    'groupId',
    'groupName',
    'groupIsEmpty',
    'sharedRunnersSetting',
    'parentSharedRunnersSetting',
    'runnerEnabledValue',
    'runnerDisabledValue',
    'runnerAllowOverrideValue',
  ],
  data() {
    return {
      isLoading: false,
      value: this.sharedRunnersSetting,
      error: null,
    };
  },
  computed: {
    isSharedRunnersToggleDisabled() {
      return this.parentSharedRunnersSetting === this.runnerDisabledValue;
    },
    sharedRunnersToggleValue() {
      return this.value === this.runnerEnabledValue;
    },
    isOverrideToggleDisabled() {
      // cannot override when sharing is enabled
      return this.isSharedRunnersToggleDisabled || this.value === this.runnerEnabledValue;
    },
    overrideToggleValue() {
      return this.value === this.runnerAllowOverrideValue;
    },
  },
  methods: {
    async onSharedRunnersToggle(enabled) {
      if (enabled) {
        this.updateSetting(this.runnerEnabledValue);
        return;
      }
      if (this.groupIsEmpty) {
        this.updateSetting(this.runnerDisabledValue);
        return;
      }

      // Confirm when disabling for a group with subgroups or projects
      const confirmDisabled = await confirmAction(I18N_CONFIRM_MESSAGE, {
        title: sprintf(I18N_CONFIRM_TITLE, { groupName: this.groupName }),
        cancelBtnText: I18N_CONFIRM_CANCEL,
        primaryBtnText: I18N_CONFIRM_OK,
        primaryBtnVariant: 'danger',
        size: 'md',
      });

      if (confirmDisabled) {
        this.updateSetting(this.runnerDisabledValue);
      }
    },
    onOverrideToggle(value) {
      const newSetting = value ? this.runnerAllowOverrideValue : this.runnerDisabledValue;
      this.updateSetting(newSetting);
    },
    updateSetting(setting) {
      if (this.isLoading) {
        return;
      }

      this.isLoading = true;

      updateGroup(this.groupId, { shared_runners_setting: setting })
        .then(() => {
          this.value = setting;
        })
        .catch((error) => {
          const message = [
            error.response?.data?.error || I18N_UPDATE_ERROR_MESSAGE,
            I18N_REFRESH_MESSAGE,
          ].join(' ');

          this.error = message;
        })
        .finally(() => {
          this.isLoading = false;
        });
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="error" variant="danger" :dismissible="false" class="gl-mb-5">
      {{ error }}
    </gl-alert>

    <gl-alert
      v-if="isSharedRunnersToggleDisabled"
      variant="warning"
      :dismissible="false"
      class="gl-mb-5"
    >
      {{ __('Shared runners are disabled for the parent group') }}
    </gl-alert>

    <section class="gl-mb-5">
      <gl-toggle
        :value="sharedRunnersToggleValue"
        :is-loading="isLoading"
        :disabled="isSharedRunnersToggleDisabled"
        :label="__('Enable shared runners for this group')"
        :help="__('Enable shared runners for all projects and subgroups in this group.')"
        data-testid="shared-runners-toggle"
        @change="onSharedRunnersToggle"
      />
    </section>

    <section class="gl-mb-5">
      <gl-toggle
        :value="overrideToggleValue"
        :is-loading="isLoading"
        :disabled="isOverrideToggleDisabled"
        :label="__('Allow projects and subgroups to override the group setting')"
        :help="__('Allows projects or subgroups in this group to override the global setting.')"
        data-testid="override-runners-toggle"
        @change="onOverrideToggle"
      />
    </section>
  </div>
</template>
