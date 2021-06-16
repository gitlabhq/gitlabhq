<script>
import { GlModal, GlSprintf, GlFormGroup, GlButton } from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';
import { ISSUABLE_TYPE } from '../constants';

export default {
  name: 'CsvImportModal',
  components: {
    GlModal,
    GlSprintf,
    GlFormGroup,
    GlButton,
  },
  inject: {
    issuableType: {
      default: '',
    },
    exportCsvPath: {
      default: '',
    },
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
  data() {
    return {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      issuableName: this.issuableType === ISSUABLE_TYPE.issues ? 'issues' : 'merge requests',
    };
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
  <gl-modal :modal-id="modalId" :title="__('Import issues')">
    <form ref="form" :action="importCsvIssuesPath" enctype="multipart/form-data" method="post">
      <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
      <p>
        {{
          __(
            "Your issues will be imported in the background. Once finished, you'll get a confirmation email.",
          )
        }}
      </p>
      <gl-form-group :label="__('Upload CSV file')" label-for="file">
        <input id="file" type="file" name="file" accept=".csv,text/csv" />
      </gl-form-group>
      <p class="text-secondary">
        {{
          __(
            'It must have a header row and at least two columns: the first column is the issue title and the second column is the issue description. The separator is automatically detected.',
          )
        }}
        <gl-sprintf :message="__('The maximum file size allowed is %{size}.')"
          ><template #size>{{ maxAttachmentSize }}</template></gl-sprintf
        >
      </p>
    </form>
    <template #modal-footer>
      <gl-button category="primary" variant="confirm" @click="submitForm">{{
        __('Import issues')
      }}</gl-button>
    </template>
  </gl-modal>
</template>
