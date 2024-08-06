<script>
import { GlForm, GlFormGroup, GlFormRadioGroup, GlModal } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { s__, __ } from '~/locale';
import csrf from '~/lib/utils/csrf';
import { CATEGORY_OPTIONS } from '~/abuse_reports/components/constants';

export default {
  name: 'WorkItemAbuseModal',
  csrf,
  i18n: {
    title: __('Report abuse to administrator'),
    label: s__('ReportAbuse|Why are you reporting this user?'),
  },
  modal: {
    id: uniqueId('work-item-abuse-modal-'),
    actionPrimary: {
      text: __('Next'),
      attributes: {
        variant: 'confirm',
      },
    },
    actionSecondary: {
      text: __('Cancel'),
      attributes: {
        variant: 'default',
      },
    },
  },
  CATEGORY_OPTIONS,
  components: {
    GlForm,
    GlFormGroup,
    GlFormRadioGroup,
    GlModal,
  },
  inject: {
    reportAbusePath: {
      default: '',
    },
  },
  props: {
    reportedUserId: {
      type: Number,
      required: true,
    },
    reportedFromUrl: {
      type: String,
      required: false,
      default: '',
    },
    showModal: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      selectedOption: CATEGORY_OPTIONS[0].value,
    };
  },
  methods: {
    closeModal() {
      this.$emit('close-modal');
    },
    submitForm() {
      this.$refs.form.$el.submit();
    },
  },
};
</script>
<template>
  <gl-modal
    size="sm"
    :visible="showModal"
    :modal-id="$options.modal.id"
    :title="$options.i18n.title"
    :action-primary="$options.modal.actionPrimary"
    :action-secondary="$options.modal.actionSecondary"
    @primary="submitForm"
    @hide="closeModal"
  >
    <gl-form ref="form" :action="reportAbusePath" method="post">
      <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />

      <input type="hidden" name="user_id" :value="reportedUserId" data-testid="input-user-id" />
      <input
        type="hidden"
        name="abuse_report[reported_from_url]"
        :value="reportedFromUrl"
        data-testid="input-referer"
      />

      <gl-form-group :label="$options.i18n.label">
        <gl-form-radio-group
          v-model="selectedOption"
          :options="$options.CATEGORY_OPTIONS"
          name="abuse_report[category]"
        />
      </gl-form-group>
    </gl-form>
  </gl-modal>
</template>
