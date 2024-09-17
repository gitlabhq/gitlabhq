<script>
import { GlAlert, GlButton, GlForm, GlFormGroup, GlFormTextarea } from '@gitlab/ui';
import RefSelector from '~/ref/components/ref_selector.vue';
import { __, s__, sprintf } from '~/locale';
import createCommitMutation from '../queries/create_commit.graphql';
import getFileMetaDataQuery from '../queries/get_file_meta.graphql';
import StepNav from './step_nav.vue';

export const i18n = {
  updateFileHeading: s__('PipelineWizard|Commit changes to your file'),
  createFileHeading: s__('PipelineWizard|Commit your new file'),
  fieldRequiredFeedback: __('This field is required'),
  commitMessageLabel: s__('PipelineWizard|Commit Message'),
  branchSelectorLabel: s__('PipelineWizard|Commit file to Branch'),
  defaultUpdateCommitMessage: s__('PipelineWizardDefaultCommitMessage|Update %{filename}'),
  defaultCreateCommitMessage: s__('PipelineWizardDefaultCommitMessage|Add %{filename}'),
  commitButtonLabel: s__('PipelineWizard|Commit'),
  commitSuccessMessage: s__('PipelineWizard|The file has been committed.'),
  errors: {
    loadError: s__(
      'PipelineWizard|There was a problem while checking whether your file already exists in the specified branch.',
    ),
    commitError: s__('PipelineWizard|There was a problem committing the changes.'),
  },
};

const COMMIT_ACTION = {
  CREATE: 'CREATE',
  UPDATE: 'UPDATE',
};

export default {
  i18n,
  name: 'PipelineWizardCommitStep',
  components: {
    RefSelector,
    GlAlert,
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormTextarea,
    StepNav,
  },
  props: {
    prev: {
      type: Object,
      required: false,
      default: null,
    },
    projectPath: {
      type: String,
      required: true,
    },
    defaultBranch: {
      type: String,
      required: true,
    },
    fileContent: {
      type: String,
      required: false,
      default: '',
    },
    filename: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      branch: this.defaultBranch,
      loading: false,
      loadError: null,
      commitError: null,
      message: null,
    };
  },
  computed: {
    fileExistsInRepo() {
      return this.project?.repository?.blobs.nodes.length > 0;
    },
    commitAction() {
      return this.fileExistsInRepo ? COMMIT_ACTION.UPDATE : COMMIT_ACTION.CREATE;
    },
    defaultMessage() {
      return sprintf(
        this.fileExistsInRepo
          ? this.$options.i18n.defaultUpdateCommitMessage
          : this.$options.i18n.defaultCreateCommitMessage,
        { filename: this.filename },
      );
    },
    isCommitButtonEnabled() {
      return this.fileExistsCheckInProgress;
    },
    fileExistsCheckInProgress() {
      return this.$apollo.queries.project.loading;
    },
    mutationPayload() {
      return {
        mutation: createCommitMutation,
        variables: {
          input: {
            projectPath: this.projectPath,
            branch: this.branch,
            message: this.message || this.defaultMessage,
            actions: [
              {
                action: this.commitAction,
                filePath: `/${this.filename}`,
                content: this.fileContent,
              },
            ],
          },
        },
      };
    },
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    project: {
      query: getFileMetaDataQuery,
      variables() {
        this.loadError = null;
        return {
          fullPath: this.projectPath,
          filePath: this.filename,
          ref: this.branch,
        };
      },
      error() {
        this.loadError = this.$options.i18n.errors.loadError;
      },
    },
  },
  methods: {
    async commit() {
      this.loading = true;
      try {
        const { data } = await this.$apollo.mutate(this.mutationPayload);
        const hasError = Boolean(data.commitCreate.errors?.length);
        if (hasError) {
          this.commitError = this.$options.i18n.errors.commitError;
        } else {
          this.handleCommitSuccess();
        }
      } catch (e) {
        this.commitError = this.$options.i18n.errors.commitError;
      } finally {
        this.loading = false;
      }
    },
    handleCommitSuccess() {
      this.$toast.show(this.$options.i18n.commitSuccessMessage);
      this.$emit('done');
    },
  },
};
</script>

<template>
  <div>
    <h4 v-if="fileExistsInRepo" key="create-heading">
      {{ $options.i18n.updateFileHeading }}
    </h4>
    <h4 v-else key="update-heading">
      {{ $options.i18n.createFileHeading }}
    </h4>
    <gl-alert
      v-if="!!loadError"
      :dismissible="false"
      class="gl-mb-5"
      data-testid="load-error"
      variant="danger"
    >
      {{ loadError }}
    </gl-alert>
    <gl-form class="gl-max-w-48">
      <gl-form-group
        :invalid-feedback="$options.i18n.fieldRequiredFeedback"
        :label="$options.i18n.commitMessageLabel"
        label-for="commit_message"
      >
        <gl-form-textarea
          id="commit_message"
          v-model="message"
          :placeholder="defaultMessage"
          data-testid="commit_message"
          no-resize
          size="md"
          @input="(v) => $emit('update:message', v)"
        />
      </gl-form-group>
      <gl-form-group
        :invalid-feedback="$options.i18n.fieldRequiredFeedback"
        :label="$options.i18n.branchSelectorLabel"
        label-for="branch"
      >
        <ref-selector id="branch" v-model="branch" :project-id="projectPath" data-testid="branch" />
      </gl-form-group>
      <gl-alert
        v-if="!!commitError"
        :dismissible="false"
        class="gl-mb-5"
        data-testid="commit-error"
        variant="danger"
      >
        {{ commitError }}
      </gl-alert>
      <step-nav show-back-button v-bind="$props" @back="$emit('back')">
        <template #after>
          <gl-button
            :disabled="isCommitButtonEnabled"
            :loading="fileExistsCheckInProgress || loading"
            category="primary"
            variant="confirm"
            @click="commit"
          >
            {{ $options.i18n.commitButtonLabel }}
          </gl-button>
        </template>
      </step-nav>
    </gl-form>
  </div>
</template>
