<script>
import { GlModal, GlFormGroup } from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';
import { __, sprintf } from '~/locale';

export default {
  i18n: {
    maximumFileSizeText: __('The maximum file size allowed is %{size}.'),
    importIssuesText: __('Import issues'),
    uploadCsvFileText: __('Upload CSV file'),
    mainText: __(
      "Your issues will be imported in the background. Once finished, you'll get a confirmation email.",
    ),
    helpText: __(
      'It must have a header row and at least two columns: the first column is the issue title and the second column is the issue description. The separator is automatically detected.',
    ),
  },
  actionPrimary: {
    text: __('Import issues'),
  },
  actionCancel: {
    text: __('Cancel'),
  },
  components: {
    GlModal,
    GlFormGroup,
  },
  inject: {
    importCsvIssuesPath: {
      default: '',
    },
    maxAttachmentSize: {
      default: 0,
    },
  },
  props: {
    modalId: {
      type: String,
      required: true,
    },
  },
  computed: {
    maxFileSizeText() {
      return sprintf(this.$options.i18n.maximumFileSizeText, { size: this.maxAttachmentSize });
    },
  },
  methods: {
    submitForm() {
      this.$refs.form.submit();
    },
  },
  csrf,
};
</script>

<template>
  <gl-modal
    :modal-id="modalId"
    :title="$options.i18n.importIssuesText"
    :action-primary="$options.actionPrimary"
    :action-cancel="$options.actionCancel"
    @primary="submitForm"
  >
    <form ref="form" :action="importCsvIssuesPath" enctype="multipart/form-data" method="post">
      <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
      <p>{{ $options.i18n.mainText }}</p>
      <gl-form-group :label="$options.i18n.uploadCsvFileText" class="gl-truncate" label-for="file">
        <input id="file" type="file" name="file" accept=".csv,text/csv" />
      </gl-form-group>
      <p class="gl-text-subtle">
        {{ $options.i18n.helpText }}
        {{ maxFileSizeText }}
      </p>
    </form>
  </gl-modal>
</template>
