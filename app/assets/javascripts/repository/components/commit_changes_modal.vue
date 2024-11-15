<script>
import {
  GlModal,
  GlFormCheckbox,
  GlFormGroup,
  GlFormInput,
  GlFormTextarea,
  GlFormRadio,
  GlFormRadioGroup,
  GlForm,
  GlSprintf,
  GlLink,
} from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';
import { __, s__ } from '~/locale';
import validation, { initFormField } from '~/vue_shared/directives/validation';
import { helpPagePath } from '~/helpers/help_page_helper';
import { getParameterByName } from '~/lib/utils/url_utility';
import {
  SECONDARY_OPTIONS_TEXT,
  COMMIT_LABEL,
  COMMIT_MESSAGE_SUBJECT_MAX_LENGTH,
  COMMIT_MESSAGE_BODY_MAX_LENGTH,
} from '../constants';

export default {
  csrf,
  components: {
    GlModal,
    GlFormCheckbox,
    GlFormGroup,
    GlFormInput,
    GlFormRadio,
    GlFormRadioGroup,
    GlFormTextarea,
    GlForm,
    GlSprintf,
    GlLink,
  },
  i18n: {
    BRANCH: __('Branch'),
    BRANCH_IN_FORK_MESSAGE: __(
      'GitLab will create a branch in your fork and start a merge request.',
    ),
    CURRENT_BRANCH_LABEL: __('Commit to the current %{branchName} branch'),
    COMMIT_CHANGES: __('Commit changes'),
    COMMIT_IN_BRANCH_MESSAGE: __(
      'Your changes can be committed to %{branchName} because a merge request is open.',
    ),
    COMMIT_LABEL,
    COMMIT_MESSAGE_HINT: __(
      'Try to keep the first line under 52 characters and the others under 72.',
    ),
    NEW_BRANCH_LABEl: __('Commit to a new branch'),
    CREATE_MR_LABEL: __('Create a merge request for this change'),
    LFS_WARNING_TITLE: __("The file you're about to delete is tracked by LFS"),
    LFS_WARNING_PRIMARY_CONTENT: s__(
      'BlobViewer|If you delete the file, it will be removed from the branch %{branch}.',
    ),
    LFS_WARNING_SECONDARY_CONTENT: s__(
      'BlobViewer|This file will still take up space in your LFS storage. %{linkStart}How do I remove tracked objects from Git LFS?%{linkEnd}',
    ),
    LFS_CONTINUE_TEXT: __('Continue…'),
    LFS_CANCEL_TEXT: __('Cancel'),
    SECONDARY_OPTIONS_TEXT,
  },
  directives: {
    validation: validation(),
  },
  props: {
    modalId: {
      type: String,
      required: true,
    },
    actionPath: {
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
    method: {
      type: String,
      required: false,
      default: 'delete',
    },
    fileContent: {
      type: String,
      required: false,
      default: null,
    },
    filePath: {
      type: String,
      required: false,
      default: null,
    },
    isEdit: {
      type: Boolean,
      required: false,
      default: false,
    },
    branchAllowsCollaboration: {
      type: Boolean,
      required: false,
      default: false,
    },
    lastCommitSha: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    const form = {
      state: false,
      showValidation: false,
      fields: {
        // fields key must match case of form name for validation directive to work
        commit_message: initFormField({ value: this.commitMessage }),
        branch_name: initFormField({
          value: this.targetBranch,
          // Branch name is pre-filled with the current branch name in two scenarios and therefore doesn't need validation:
          // 1. When the user doesn't have permission to push to the repo (e.g. guest user)
          // 2. When the user can push directly to the current branch
          skipValidation: !this.canPushCode || this.canPushToBranch,
        }),
      },
    };
    return {
      lfsWarningDismissed: false,
      loading: false,
      createNewBranch: false,
      createNewMr: true,
      form,
    };
  },
  computed: {
    primaryOptions() {
      const defaultOptions = {
        text: this.$options.i18n.COMMIT_CHANGES,
        attributes: {
          variant: 'confirm',
          loading: this.loading,
          disabled: this.loading || !this.form.state,
          'data-testid': 'commit-change-modal-commit-button',
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
      return this.isUsingLfs && !this.lfsWarningDismissed && !this.isEdit;
    },
    title() {
      return this.showLfsWarning
        ? this.$options.i18n.LFS_WARNING_TITLE
        : this.$options.i18n.COMMIT_CHANGES;
    },
    showForm() {
      return !this.isUsingLfs || (this.isUsingLfs && this.lfsWarningDismissed) || this.isEdit;
    },
    fromMergeRequestIid() {
      return getParameterByName('from_merge_request_iid') || '';
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
      window.onbeforeunload = null;
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
  deleteLfsHelpPath: helpPagePath('topics/git/lfs', {
    anchor: 'delete-a-git-lfs-file-from-repository-history',
  }),
};
</script>

<template>
  <gl-modal
    :ref="modalId"
    v-bind="$attrs"
    :modal-id="modalId"
    :title="title"
    data-testid="commit-change-modal"
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
    <div v-if="showForm">
      <gl-form ref="form" novalidate :action="actionPath" method="post">
        <input type="hidden" name="_method" :value="method" />
        <template v-if="isEdit">
          <input type="hidden" name="content" :value="fileContent" />
          <input type="hidden" name="file_path" :value="filePath" />
          <input type="hidden" name="last_commit_sha" :value="lastCommitSha" />
          <input type="hidden" name="from_merge_request_iid" :value="fromMergeRequestIid" />
        </template>
        <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
        <template v-if="emptyRepo">
          <input type="hidden" name="branch_name" :value="originalBranch" class="js-branch-name" />
        </template>
        <template v-else>
          <input type="hidden" name="original_branch" :value="originalBranch" />
          <input v-if="createNewMr" type="hidden" name="create_merge_request" value="1" />
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
            <p v-if="showHint" class="form-text gl-text-subtle" data-testid="hint">
              {{ $options.i18n.COMMIT_MESSAGE_HINT }}
            </p>
          </gl-form-group>
          <gl-form-group
            v-if="canPushCode"
            :label="$options.i18n.BRANCH"
            label-for="branch_selection"
          >
            <template v-if="canPushToBranch">
              <gl-form-radio-group
                v-model="createNewBranch"
                name="branch_selection"
                :label="$options.i18n.BRANCH"
              >
                <gl-form-radio :value="false">
                  <gl-sprintf :message="$options.i18n.CURRENT_BRANCH_LABEL">
                    <template #branchName
                      ><code>{{ originalBranch }}</code>
                    </template>
                  </gl-sprintf>
                </gl-form-radio>
                <gl-form-radio :value="true">
                  {{ $options.i18n.NEW_BRANCH_LABEl }}
                </gl-form-radio>
              </gl-form-radio-group>
              <div v-if="createNewBranch" class="gl-ml-6">
                <gl-form-input
                  v-model="form.fields['branch_name'].value"
                  v-validation:[form.showValidation]
                  :state="form.fields['branch_name'].state"
                  :disabled="loading"
                  name="branch_name"
                  required
                  class="gl-mt-2"
                />
                <gl-form-checkbox v-if="createNewBranch" v-model="createNewMr" class="gl-mt-4">
                  <span>
                    {{ $options.i18n.CREATE_MR_LABEL }}
                  </span>
                </gl-form-checkbox>
              </div>
            </template>

            <template v-else>
              <label for="branchNameInput" class="gl-font-normal">
                {{ $options.i18n.NEW_BRANCH_LABEl }}
              </label>
              <gl-form-input
                id="branchNameInput"
                v-model="form.fields['branch_name'].value"
                v-validation:[form.showValidation]
                :state="form.fields['branch_name'].state"
                :disabled="loading"
                name="branch_name"
                required
                class="gl-mt-2"
              />
              <gl-form-checkbox v-model="createNewMr" class="gl-mt-4">
                <span>
                  {{ $options.i18n.CREATE_MR_LABEL }}
                </span>
              </gl-form-checkbox>
            </template>
          </gl-form-group>
          <template v-else>
            <gl-sprintf
              v-if="branchAllowsCollaboration"
              :message="$options.i18n.COMMIT_IN_BRANCH_MESSAGE"
            >
              <template #branchName
                ><strong>{{ originalBranch }}</strong>
              </template>
            </gl-sprintf>
            <p v-else class="gl-my-0">{{ $options.i18n.BRANCH_IN_FORK_MESSAGE }}</p>
          </template>
        </template>
      </gl-form>
    </div>
  </gl-modal>
</template>
