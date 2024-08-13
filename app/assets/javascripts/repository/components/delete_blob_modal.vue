<script>
import {
  GlModal,
  GlFormGroup,
  GlFormInput,
  GlFormTextarea,
  GlToggle,
  GlForm,
  GlSprintf,
  GlLink,
} from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';
import { __, s__ } from '~/locale';
import validation from '~/vue_shared/directives/validation';
import { helpPagePath } from '~/helpers/help_page_helper';
import {
  SECONDARY_OPTIONS_TEXT,
  COMMIT_LABEL,
  TARGET_BRANCH_LABEL,
  TOGGLE_CREATE_MR_LABEL,
  COMMIT_MESSAGE_SUBJECT_MAX_LENGTH,
  COMMIT_MESSAGE_BODY_MAX_LENGTH,
} from '../constants';

const initFormField = ({ value, required = true, skipValidation = false }) => ({
  value,
  required,
  state: skipValidation ? true : null,
  feedback: null,
});

export default {
  csrf,
  components: {
    GlModal,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    GlToggle,
    GlForm,
    GlSprintf,
    GlLink,
  },
  i18n: {
    LFS_WARNING_TITLE: __("The file you're about to delete is tracked by LFS"),
    LFS_WARNING_PRIMARY_CONTENT: s__(
      'BlobViewer|If you delete the file, it will be removed from the branch %{branch}.',
    ),
    LFS_WARNING_SECONDARY_CONTENT: s__(
      'BlobViewer|This file will still take up space in your LFS storage. %{linkStart}How do I remove tracked objects from Git LFS?%{linkEnd}',
    ),
    LFS_CONTINUE_TEXT: __('Continue…'),
    LFS_CANCEL_TEXT: __('Cancel'),
    PRIMARY_OPTIONS_TEXT: __('Delete file'),
    SECONDARY_OPTIONS_TEXT,
    COMMIT_LABEL,
    TARGET_BRANCH_LABEL,
    TOGGLE_CREATE_MR_LABEL,
    COMMIT_MESSAGE_HINT: __(
      'Try to keep the first line under 52 characters and the others under 72.',
    ),
  },
  directives: {
    validation: validation(),
  },
  props: {
    modalId: {
      type: String,
      required: true,
    },
    modalTitle: {
      type: String,
      required: true,
    },
    deletePath: {
      type: String,
      required: true,
    },
    commitMessage: {
      type: String,
      required: true,
    },
    targetBranch: {
      type: String,
      required: true,
    },
    originalBranch: {
      type: String,
      required: true,
    },
    canPushCode: {
      type: Boolean,
      required: true,
    },
    canPushToBranch: {
      type: Boolean,
      required: true,
    },
    emptyRepo: {
      type: Boolean,
      required: true,
    },
    isUsingLfs: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    const form = {
      state: false,
      showValidation: false,
      fields: {
        // fields key must match case of form name for validation directive to work
        commit_message: initFormField({ value: this.commitMessage }),
        branch_name: initFormField({ value: this.targetBranch, skipValidation: !this.canPushCode }),
      },
    };
    return {
      lfsWarningDismissed: false,
      loading: false,
      createNewMr: true,
      error: '',
      form,
    };
  },
  computed: {
    primaryOptions() {
      const defaultOptions = {
        text: this.$options.i18n.PRIMARY_OPTIONS_TEXT,
        attributes: {
          variant: 'danger',
          loading: this.loading,
          disabled: this.loading || !this.form.state,
        },
      };

      const lfsWarningOptions = {
        text: this.$options.i18n.LFS_CONTINUE_TEXT,
        attributes: { variant: 'confirm' },
      };

      return this.showLfsWarning ? lfsWarningOptions : defaultOptions;
    },
    cancelOptions() {
      return {
        text: this.$options.i18n.SECONDARY_OPTIONS_TEXT,
        attributes: {
          disabled: this.loading,
        },
      };
    },
    showCreateNewMrToggle() {
      return this.canPushCode && this.form.fields.branch_name.value !== this.originalBranch;
    },
    formCompleted() {
      return this.form.fields.commit_message.value && this.form.fields.branch_name.value;
    },
    showHint() {
      const splitCommitMessageByLineBreak = this.form.fields.commit_message.value
        .trim()
        .split('\n');
      const [firstLine, ...otherLines] = splitCommitMessageByLineBreak;

      const hasFirstLineExceedMaxLength = firstLine.length > COMMIT_MESSAGE_SUBJECT_MAX_LENGTH;

      const hasOtherLineExceedMaxLength =
        Boolean(otherLines.length) &&
        otherLines.some((text) => text.length > COMMIT_MESSAGE_BODY_MAX_LENGTH);

      return (
        !this.form.fields.commit_message.feedback &&
        (hasFirstLineExceedMaxLength || hasOtherLineExceedMaxLength)
      );
    },
    showLfsWarning() {
      return this.isUsingLfs && !this.lfsWarningDismissed;
    },
    title() {
      return this.showLfsWarning ? this.$options.i18n.LFS_WARNING_TITLE : this.modalTitle;
    },
    showDeleteForm() {
      return !this.isUsingLfs || (this.isUsingLfs && this.lfsWarningDismissed);
    },
  },
  methods: {
    show() {
      this.$refs[this.modalId].show();
      this.lfsWarningDismissed = false;
    },
    cancel() {
      this.$refs[this.modalId].hide();
    },
    async handleContinueLfsWarning() {
      this.lfsWarningDismissed = true;
      await this.$nextTick();
      this.$refs.message?.$el.focus();
    },
    async handlePrimaryAction(e) {
      e.preventDefault(); // Prevent modal from closing

      if (this.showLfsWarning) {
        this.lfsWarningDismissed = true;
        await this.$nextTick();
        this.$refs.message?.$el.focus();
        return;
      }

      this.form.showValidation = true;

      if (!this.form.state) {
        return;
      }

      this.loading = true;
      this.form.showValidation = false;
      this.$refs.form.$el.submit();
    },
  },
  // eslint-disable-next-line local-rules/require-valid-help-page-path
  deleteLfsHelpPath: helpPagePath('topics/git/lfs/index', { anchor: 'removing-objects-from-lfs' }),
};
</script>

<template>
  <gl-modal
    :ref="modalId"
    v-bind="$attrs"
    :modal-id="modalId"
    :title="title"
    :action-primary="primaryOptions"
    :action-cancel="cancelOptions"
    @primary="handlePrimaryAction"
  >
    <div v-if="showLfsWarning">
      <p>
        <gl-sprintf :message="$options.i18n.LFS_WARNING_PRIMARY_CONTENT">
          <template #branch>
            <code>{{ targetBranch }}</code>
          </template>
        </gl-sprintf>
      </p>

      <p>
        <gl-sprintf :message="$options.i18n.LFS_WARNING_SECONDARY_CONTENT">
          <template #link="{ content }">
            <gl-link :href="$options.deleteLfsHelpPath">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
    </div>
    <div v-if="showDeleteForm">
      <gl-form ref="form" novalidate :action="deletePath" method="post">
        <input type="hidden" name="_method" value="delete" />
        <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
        <template v-if="emptyRepo">
          <input type="hidden" name="branch_name" :value="originalBranch" class="js-branch-name" />
        </template>
        <template v-else>
          <input type="hidden" name="original_branch" :value="originalBranch" />
          <input
            v-if="createNewMr || !canPushToBranch"
            type="hidden"
            name="create_merge_request"
            value="1"
          />
          <gl-form-group
            :label="$options.i18n.COMMIT_LABEL"
            label-for="commit_message"
            :invalid-feedback="form.fields['commit_message'].feedback"
          >
            <gl-form-textarea
              id="commit_message"
              ref="message"
              v-model="form.fields['commit_message'].value"
              v-validation:[form.showValidation]
              name="commit_message"
              no-resize
              data-testid="commit-message-field"
              :state="form.fields['commit_message'].state"
              :disabled="loading"
              required
            />
            <p v-if="showHint" class="form-text gl-text-gray-600" data-testid="hint">
              {{ $options.i18n.COMMIT_MESSAGE_HINT }}
            </p>
          </gl-form-group>
          <gl-form-group
            v-if="canPushCode"
            :label="$options.i18n.TARGET_BRANCH_LABEL"
            label-for="branch_name"
            :invalid-feedback="form.fields['branch_name'].feedback"
          >
            <gl-form-input
              id="branch_name"
              v-model="form.fields['branch_name'].value"
              v-validation:[form.showValidation]
              :state="form.fields['branch_name'].state"
              :disabled="loading"
              name="branch_name"
              required
            />
          </gl-form-group>
          <gl-toggle
            v-if="showCreateNewMrToggle"
            v-model="createNewMr"
            :disabled="loading"
            :label="$options.i18n.TOGGLE_CREATE_MR_LABEL"
          />
        </template>
      </gl-form>
    </div>
  </gl-modal>
</template>
