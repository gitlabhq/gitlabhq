<script>
import { GlFormGroup, GlFormInput, GlModal, GlSprintf, GlLink } from '@gitlab/ui';
import { isValidCron } from 'cron-validator';
import { mapActions, mapState } from 'vuex';
import { __ } from '~/locale';
import TimezoneDropdown from '~/vue_shared/components/timezone_dropdown.vue';
import { mapComputed } from '~/vuex_shared/bindings';

export default {
  components: {
    GlFormGroup,
    GlFormInput,
    GlModal,
    GlSprintf,
    GlLink,
    TimezoneDropdown,
  },
  modalOptions: {
    ref: 'modal',
    modalId: 'deploy-freeze-modal',
    actionCancel: {
      text: __('Cancel'),
    },
    static: true,
    lazy: true,
  },
  translations: {
    cronPlaceholder: __('* * * * *'),
    cronSyntaxInstructions: __(
      'Define a custom deploy freeze pattern with %{cronSyntaxStart}cron syntax%{cronSyntaxEnd}',
    ),
    addTitle: __('Add deploy freeze'),
    editTitle: __('Edit deploy freeze'),
  },
  computed: {
    ...mapState([
      'projectId',
      'selectedId',
      'selectedTimezone',
      'timezoneData',
      'freezeStartCron',
      'freezeEndCron',
    ]),
    ...mapComputed([
      { key: 'freezeStartCron', updateFn: 'setFreezeStartCron' },
      { key: 'freezeEndCron', updateFn: 'setFreezeEndCron' },
    ]),
    addDeployFreezeButton() {
      return {
        text: this.isEditing ? __('Save deploy freeze') : __('Add deploy freeze'),
        attributes: [
          { variant: 'confirm' },
          {
            disabled:
              !isValidCron(this.freezeStartCron) ||
              !isValidCron(this.freezeEndCron) ||
              !this.selectedTimezone,
          },
        ],
      };
    },
    invalidFreezeStartCron() {
      return this.invalidCronMessage(this.freezeStartCronState);
    },
    freezeStartCronState() {
      return Boolean(!this.freezeStartCron || isValidCron(this.freezeStartCron));
    },
    invalidFreezeEndCron() {
      return this.invalidCronMessage(this.freezeEndCronState);
    },
    freezeEndCronState() {
      return Boolean(!this.freezeEndCron || isValidCron(this.freezeEndCron));
    },
    timezone: {
      get() {
        return this.selectedTimezone;
      },
      set(selectedTimezone) {
        this.setSelectedTimezone(selectedTimezone);
      },
    },
    isEditing() {
      return Boolean(this.selectedId);
    },
    modalTitle() {
      return this.isEditing
        ? this.$options.translations.editTitle
        : this.$options.translations.addTitle;
    },
  },
  methods: {
    ...mapActions(['addFreezePeriod', 'updateFreezePeriod', 'setSelectedTimezone', 'resetModal']),
    resetModalHandler() {
      this.resetModal();
    },
    invalidCronMessage(validCronState) {
      if (!validCronState) {
        return __('This Cron pattern is invalid');
      }
      return '';
    },
    submit() {
      if (this.isEditing) {
        this.updateFreezePeriod();
      } else {
        this.addFreezePeriod();
      }
    },
  },
};
</script>

<template>
  <gl-modal
    v-bind="$options.modalOptions"
    :title="modalTitle"
    :action-primary="addDeployFreezeButton"
    @primary="submit"
    @canceled="resetModalHandler"
  >
    <p>
      <gl-sprintf :message="$options.translations.cronSyntaxInstructions">
        <template #cronSyntax="{ content }">
          <gl-link href="https://crontab.guru/" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>

    <gl-form-group
      :label="__('Freeze start')"
      label-for="deploy-freeze-start"
      :invalid-feedback="invalidFreezeStartCron"
      :state="freezeStartCronState"
    >
      <gl-form-input
        id="deploy-freeze-start"
        v-model="freezeStartCron"
        class="gl-font-monospace!"
        data-qa-selector="deploy_freeze_start_field"
        :placeholder="this.$options.translations.cronPlaceholder"
        :state="freezeStartCronState"
        trim
      />
    </gl-form-group>

    <gl-form-group
      :label="__('Freeze end')"
      label-for="deploy-freeze-end"
      :invalid-feedback="invalidFreezeEndCron"
      :state="freezeEndCronState"
    >
      <gl-form-input
        id="deploy-freeze-end"
        v-model="freezeEndCron"
        class="gl-font-monospace!"
        data-qa-selector="deploy_freeze_end_field"
        :placeholder="this.$options.translations.cronPlaceholder"
        :state="freezeEndCronState"
        trim
      />
    </gl-form-group>

    <gl-form-group :label="__('Cron time zone')" label-for="cron-time-zone-dropdown">
      <timezone-dropdown v-model="timezone" :timezone-data="timezoneData" />
    </gl-form-group>
  </gl-modal>
</template>
