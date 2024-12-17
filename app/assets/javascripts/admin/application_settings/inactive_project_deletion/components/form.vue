<script>
import {
  GlFormCheckbox,
  GlFormGroup,
  GlFormInputGroup,
  GlFormInput,
  GlLink,
  GlSprintf,
} from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __, s__ } from '~/locale';

export default {
  name: 'InactiveProjectDeletionForm',
  components: {
    GlFormCheckbox,
    GlFormGroup,
    GlFormInputGroup,
    GlFormInput,
    GlLink,
    GlSprintf,
  },
  props: {
    deleteInactiveProjects: {
      type: Boolean,
      required: false,
      default: false,
    },
    inactiveProjectsDeleteAfterMonths: {
      type: Number,
      required: false,
      default: 2,
    },
    inactiveProjectsMinSizeMb: {
      type: Number,
      required: false,
      default: 0,
    },
    inactiveProjectsSendWarningEmailAfterMonths: {
      type: Number,
      required: false,
      default: 1,
    },
  },
  data() {
    return {
      enabled: this.deleteInactiveProjects,
      deleteAfterMonths: this.inactiveProjectsDeleteAfterMonths,
      minSizeMb: this.inactiveProjectsMinSizeMb,
      sendWarningEmailAfterMonths: this.inactiveProjectsSendWarningEmailAfterMonths,
    };
  },
  computed: {
    isMinSizeMbValid() {
      return parseInt(this.minSizeMb, 10) >= 0;
    },
    isDeleteAfterMonthsValid() {
      return (
        parseInt(this.deleteAfterMonths, 10) > 0 &&
        parseInt(this.deleteAfterMonths, 10) > parseInt(this.sendWarningEmailAfterMonths, 10)
      );
    },
    isSendWarningEmailAfterMonthsValid() {
      return parseInt(this.sendWarningEmailAfterMonths, 10) > 0;
    },
  },
  watch: {
    isSendWarningEmailAfterMonthsValid() {
      this.checkValidity(
        this.$refs.sendWarningEmailAfterMonthsInput,
        this.$options.i18n.sendWarningEmailAfterMonthsInvalidFeedback,
        this.isSendWarningEmailAfterMonthsValid,
      );
    },
    isDeleteAfterMonthsValid() {
      this.checkValidity(
        this.$refs.deleteAfterMonthsInput,
        this.$options.i18n.deleteAfterMonthsInvalidFeedback,
        this.isDeleteAfterMonthsValid,
      );
    },
  },
  methods: {
    checkValidity(ref, feedback, valid) {
      // These form fields are used within a HAML created form and we don't have direct access to the submit button
      // So we set the validity of the field so the HAML form can't be submitted until this is set back to blank
      if (valid) {
        ref.$el.setCustomValidity('');
      } else {
        ref.$el.setCustomValidity(feedback);
      }
    },
  },
  i18n: {
    checkboxLabel: s__('AdminSettings|Delete inactive projects'),
    checkboxHelp: s__(
      'AdminSettings|Configure when inactive projects should be automatically deleted. %{linkStart}What are inactive projects?%{linkEnd}',
    ),
    checkboxHelpDocLink: helpPagePath('administration/inactive_project_deletion'),
    minSizeMbLabel: s__('AdminSettings|When to delete inactive projects'),
    minSizeMbDescription: s__('AdminSettings|Delete inactive projects that exceed'),
    minSizeMbInvalidFeedback: s__('AdminSettings|Minimum size must be at least 0.'),
    deleteAfterMonthsLabel: s__('AdminSettings|Delete project after'),
    deleteAfterMonthsInvalidFeedback: s__(
      "AdminSettings|You can't delete projects before the warning email is sent.",
    ),
    sendWarningEmailAfterMonthsLabel: s__('AdminSettings|Send warning email'),
    sendWarningEmailAfterMonthsDescription: s__(
      'AdminSettings|Send email to maintainers after project is inactive for',
    ),
    sendWarningEmailAfterMonthsHelp: s__(
      'AdminSettings|Requires %{linkStart}email notifications%{linkEnd}',
    ),
    sendWarningEmailAfterMonthsDocLink: helpPagePath('user/profile/notifications'),
    sendWarningEmailAfterMonthsInvalidFeedback: s__(
      'AdminSettings|Setting must be greater than 0.',
    ),
    mbAppend: __('MB'),
    monthsAppend: __('months'),
  },
};
</script>
<template>
  <div>
    <gl-form-group>
      <input name="application_setting[delete_inactive_projects]" type="hidden" :value="enabled" />
      <gl-form-checkbox v-model="enabled">
        {{ $options.i18n.checkboxLabel }}

        <template #help>
          <gl-sprintf :message="$options.i18n.checkboxHelp">
            <template #link="{ content }">
              <gl-link :href="$options.i18n.checkboxHelpDocLink" target="_blank">
                {{ content }}
              </gl-link>
            </template>
          </gl-sprintf>
        </template>
      </gl-form-checkbox>
    </gl-form-group>

    <div v-if="enabled" class="gl-ml-6" data-testid="inactive-project-deletion-settings">
      <gl-form-group
        :label="$options.i18n.minSizeMbLabel"
        :label-description="$options.i18n.minSizeMbDescription"
        :state="isMinSizeMbValid"
        data-testid="min-size-group"
      >
        <template #invalid-feedback>
          <div class="gl-w-2/5">{{ $options.i18n.minSizeMbInvalidFeedback }}</div>
        </template>
        <gl-form-input-group>
          <gl-form-input
            ref="minSizeMbInput"
            v-model="minSizeMb"
            :state="isMinSizeMbValid"
            name="application_setting[inactive_projects_min_size_mb]"
            width="md"
            type="number"
            :min="0"
            data-testid="min-size-input"
            @change="
              checkValidity(
                $refs.minSizeMbInput,
                $options.i18n.minSizeMbInvalidFeedback,
                isMinSizeMbValid,
              )
            "
          />

          <template #append>
            <div class="input-group-text" data-testid="min-size-input-group-text">
              {{ $options.i18n.mbAppend }}
            </div>
          </template>
        </gl-form-input-group>
      </gl-form-group>

      <div class="gl-border-l gl-pl-6">
        <gl-form-group
          :label="$options.i18n.deleteAfterMonthsLabel"
          :state="isDeleteAfterMonthsValid"
          data-testid="delete-after-months-group"
        >
          <template #invalid-feedback>
            <div class="gl-w-3/10">{{ $options.i18n.deleteAfterMonthsInvalidFeedback }}</div>
          </template>
          <gl-form-input-group>
            <gl-form-input
              ref="deleteAfterMonthsInput"
              v-model="deleteAfterMonths"
              :state="isDeleteAfterMonthsValid"
              name="application_setting[inactive_projects_delete_after_months]"
              width="sm"
              type="number"
              :min="0"
              data-testid="delete-after-months-input"
            />

            <template #append>
              <div class="input-group-text" data-testid="delete-after-months-input-group-text">
                {{ $options.i18n.monthsAppend }}
              </div>
            </template>
          </gl-form-input-group>
        </gl-form-group>

        <gl-form-group
          :label="$options.i18n.sendWarningEmailAfterMonthsLabel"
          :label-description="$options.i18n.sendWarningEmailAfterMonthsDescription"
          :state="isSendWarningEmailAfterMonthsValid"
          class="gl-max-w-26"
          data-testid="send-warning-email-after-months-group"
        >
          <template #invalid-feedback>
            <div class="gl-w-3/10">
              {{ $options.i18n.sendWarningEmailAfterMonthsInvalidFeedback }}
            </div>
          </template>
          <gl-form-input-group>
            <gl-form-input
              ref="sendWarningEmailAfterMonthsInput"
              v-model="sendWarningEmailAfterMonths"
              :state="isSendWarningEmailAfterMonthsValid"
              name="application_setting[inactive_projects_send_warning_email_after_months]"
              width="sm"
              type="number"
              :min="0"
              data-testid="send-warning-email-after-months-input"
            />

            <template #append>
              <div
                class="input-group-text"
                data-testid="send-warning-email-after-months-input-group-text"
              >
                {{ $options.i18n.monthsAppend }}
              </div>
            </template>
          </gl-form-input-group>

          <template #description>
            <gl-sprintf :message="$options.i18n.sendWarningEmailAfterMonthsHelp">
              <template #link="{ content }">
                <gl-link :href="$options.i18n.sendWarningEmailAfterMonthsDocLink" target="_blank">
                  {{ content }}
                </gl-link>
              </template>
            </gl-sprintf>
          </template>
        </gl-form-group>
      </div>
    </div>
  </div>
</template>
