<script>
import { GlFormGroup, GlFormInput, GlFormRadioGroup, GlFormTextarea } from '@gitlab/ui';
import { escape as esc } from 'lodash';
import { __, s__, sprintf } from '~/locale';

const defaultFileName = (dashboard) => dashboard.path.split('/').reverse()[0];

export default {
  components: {
    GlFormGroup,
    GlFormInput,
    GlFormRadioGroup,
    GlFormTextarea,
  },
  props: {
    dashboard: {
      type: Object,
      required: true,
    },
    defaultBranch: {
      type: String,
      required: true,
    },
  },
  radioVals: {
    /* Use the default branch (e.g. main) */
    DEFAULT: 'DEFAULT',
    /* Create a new branch */
    NEW: 'NEW',
  },
  data() {
    return {
      form: {
        dashboard: this.dashboard.path,
        fileName: defaultFileName(this.dashboard),
        commitMessage: '',
      },
      branchName: '',
      branchOption: this.$options.radioVals.NEW,
      branchOptions: [
        {
          value: this.$options.radioVals.DEFAULT,
          html: sprintf(
            __('Commit to %{branchName} branch'),
            {
              branchName: `<strong>${esc(this.defaultBranch)}</strong>`,
            },
            false,
          ),
        },
        { value: this.$options.radioVals.NEW, text: __('Create new branch') },
      ],
    };
  },
  computed: {
    defaultCommitMsg() {
      return sprintf(s__('Metrics|Create custom dashboard %{fileName}'), {
        fileName: this.form.fileName,
      });
    },
    fileNameState() {
      // valid if empty or *.yml
      return !(this.form.fileName && !this.form.fileName.endsWith('.yml'));
    },
    fileNameFeedback() {
      return !this.fileNameState ? s__('The file name should have a .yml extension') : '';
    },
  },
  mounted() {
    this.change();
  },
  methods: {
    change() {
      this.$emit('change', {
        ...this.form,
        commitMessage: this.form.commitMessage || this.defaultCommitMsg,
        branch:
          this.branchOption === this.$options.radioVals.NEW ? this.branchName : this.defaultBranch,
      });
    },
    focus(option) {
      if (option === this.$options.radioVals.NEW) {
        this.$nextTick(() => {
          this.$refs.branchName.$el.focus();
        });
      }
    },
  },
};
</script>
<template>
  <form @change="change">
    <p class="text-muted">
      {{
        s__(`Metrics|You can save a copy of this dashboard to your repository
      so it can be customized. Select a file name and branch to save it.`)
      }}
    </p>
    <gl-form-group
      ref="fileNameFormGroup"
      :label="__('File name')"
      :state="fileNameState"
      :invalid-feedback="fileNameFeedback"
      label-size="sm"
      label-for="fileName"
    >
      <gl-form-input
        id="fileName"
        ref="fileName"
        v-model="form.fileName"
        data-qa-selector="duplicate_dashboard_filename_field"
        :required="true"
      />
    </gl-form-group>
    <gl-form-group :label="__('Branch')" label-size="sm" label-for="branch">
      <gl-form-radio-group
        ref="branchOption"
        v-model="branchOption"
        :checked="$options.radioVals.NEW"
        :stacked="true"
        :options="branchOptions"
        @change="focus"
      />
      <gl-form-input
        v-show="branchOption === $options.radioVals.NEW"
        id="branchName"
        ref="branchName"
        v-model="branchName"
      />
    </gl-form-group>
    <gl-form-group
      :label="__('Commit message (optional)')"
      label-size="sm"
      label-for="commitMessage"
    >
      <gl-form-textarea
        id="commitMessage"
        ref="commitMessage"
        v-model="form.commitMessage"
        :placeholder="defaultCommitMsg"
      />
    </gl-form-group>
  </form>
</template>
