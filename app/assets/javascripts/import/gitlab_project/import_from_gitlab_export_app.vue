<script>
import { GlButton, GlFormGroup, GlFormInput, GlAnimatedUploadIcon } from '@gitlab/ui';
import { kebabCase } from 'lodash';
import { s__ } from '~/locale';
import validation from '~/vue_shared/directives/validation';
import csrf from '~/lib/utils/csrf';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';
import { START_RULE, CONTAINS_RULE } from '~/projects/project_name_rules';
import NewProjectDestinationSelect from '~/projects/new_v2/components/project_destination_select.vue';

const feedbackMap = {
  valueMissing: {
    isInvalid: (el) => el.validity?.valueMissing,
    message: s__('ProjectsNew|Please enter a valid project name.'),
  },
  nameStartPattern: {
    isInvalid: (el) => el.validity?.patternMismatch && !START_RULE.reg.test(el.value),
    message: START_RULE.msg,
  },
  nameContainsPattern: {
    isInvalid: (el) => el.validity?.patternMismatch && !CONTAINS_RULE.reg.test(el.value),
    message: CONTAINS_RULE.msg,
  },
};

const initFormField = ({ value = null, required = true } = {}) => ({
  value,
  required,
  state: null,
  feedback: null,
});

export default {
  components: {
    GlButton,
    GlFormGroup,
    GlFormInput,
    GlAnimatedUploadIcon,
    FileIcon,
    MultiStepFormTemplate,
    NewProjectDestinationSelect,
  },
  directives: {
    validation: validation(feedbackMap),
  },
  props: {
    backButtonPath: {
      type: String,
      required: true,
    },
    namespaceFullPath: {
      type: String,
      required: true,
    },
    namespaceId: {
      type: String,
      required: true,
    },
    rootPath: {
      type: String,
      required: true,
    },
    importGitlabProjectPath: {
      type: String,
      required: true,
    },
  },
  data() {
    const form = {
      state: false,
      showValidation: false,
      fields: {
        name: initFormField(),
        path: initFormField(),
      },
    };
    return {
      file: null,
      filePreviewURL: null,
      form,
      animateUploadIcon: false,
      dropzoneState: true,
    };
  },
  computed: {
    formattedFileSize() {
      return numberToHumanSize(this.file.size);
    },
  },
  watch: {
    // eslint-disable-next-line func-names
    'form.fields.name.value': function (newVal) {
      this.form.fields.path.value = kebabCase(newVal);
    },
  },
  methods: {
    setFile() {
      this.file = this.$refs.fileUpload.files['0'];

      const fileUrlReader = new FileReader();

      fileUrlReader.readAsDataURL(this.file);

      fileUrlReader.onload = (e) => {
        this.filePreviewURL = e.target?.result;
      };
      this.dropzoneState = true;
    },
    onDropzoneMouseEnter() {
      this.animateUploadIcon = true;
    },
    onDropzoneMouseLeave() {
      this.animateUploadIcon = false;
    },
    openFileUpload() {
      this.$refs.fileUpload.click();
    },
    onSubmit() {
      if (!this.form.state) {
        this.form.showValidation = true;
      }

      if (this.file === null) {
        this.dropzoneState = false;
      }

      if (!this.form.state || !this.dropzoneState) {
        return;
      }

      this.$refs.form.submit();
    },
  },
  csrf,
  projectNamePattern: `(${START_RULE.reg.source})|(${CONTAINS_RULE.reg.source})`,
  validFileMimetypes: ['application/gzip'],
};
</script>

<template>
  <form
    ref="form"
    :action="importGitlabProjectPath"
    enctype="multipart/form-data"
    method="post"
    @submit.prevent="onSubmit"
  >
    <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
    <multi-step-form-template
      :title="__('Import an exported GitLab project')"
      :current-step="3"
      :steps-total="3"
    >
      <template #form>
        <gl-form-group
          :label="__('Project name')"
          label-for="name"
          :description="
            s__(
              'ProjectsNew|Must start with a lowercase or uppercase letter, digit, emoji, or underscore. Can also contain dots, pluses, dashes, or spaces.',
            )
          "
          :invalid-feedback="form.fields.name.feedback"
          data-testid="project-name-form-group"
        >
          <gl-form-input
            id="name"
            v-model="form.fields.name.value"
            v-validation:[form.showValidation]
            :state="form.fields.name.state"
            :pattern="$options.projectNamePattern"
            name="name"
            required
            :placeholder="s__('ProjectsNew|My awesome project')"
            data-testid="project-name"
          />
        </gl-form-group>

        <div class="gl-flex gl-flex-col gl-gap-4 sm:gl-flex-row">
          <gl-form-group
            :label="s__('ProjectsNew|Choose a group')"
            class="sm:gl-w-1/2"
            label-for="namespace"
          >
            <new-project-destination-select
              toggle-aria-labelled-by="namespace"
              :namespace-full-path="namespaceFullPath"
              :namespace-id="namespaceId"
              :root-url="rootPath"
            />
          </gl-form-group>

          <div class="gl-mt-2 gl-hidden gl-pt-6 sm:gl-block">{{ __('/') }}</div>

          <gl-form-group
            :label="s__('ProjectsNew|Project slug')"
            label-for="path"
            class="sm:gl-w-1/2"
            :invalid-feedback="form.fields.path.feedback"
          >
            <gl-form-input
              id="path"
              v-model="form.fields.path.value"
              v-validation:[form.showValidation]
              :validation-message="s__('ProjectsNew|Please enter a valid project slug.')"
              :state="form.fields.path.state"
              name="path"
              required
              :placeholder="s__('ProjectsNew|my-awesome-project')"
              data-testid="project-slug"
            />
          </gl-form-group>
        </div>

        <p class="-gl-mt-3 gl-text-base gl-leading-normal gl-text-subtle">
          {{
            s__(
              "ProjectsNew|To move or copy an entire GitLab project from another GitLab installation to this one, navigate to the original project's settings page, generate an export file, and upload it here.",
            )
          }}
        </p>

        <gl-form-group
          :label="s__('ProjectsNew|GitLab project export')"
          label-for="file-button"
          :invalid-feedback="s__('ProjectsNew|Please upload a valid GitLab project export file.')"
          :state="dropzoneState"
          data-testid="project-file-form-group"
        >
          <button
            id="file-button"
            class="upload-dropzone-card upload-dropzone-border gl-mb-0 gl-h-full gl-w-full gl-items-center gl-justify-center gl-bg-default gl-px-5 gl-py-4"
            type="button"
            data-testid="dropzone-button"
            @click="openFileUpload"
            @mouseenter="onDropzoneMouseEnter"
            @mouseleave="onDropzoneMouseLeave"
          >
            <div
              v-if="file"
              class="gl-flex gl-w-full gl-flex-col gl-items-center gl-justify-center gl-gap-3"
            >
              <file-icon :file-name="file.name" :size="24" class="gl-flex" />
              <span>
                {{ file.name }}
                &middot;
                <span class="gl-text-subtle">{{ formattedFileSize }}</span>
              </span>
            </div>
            <div v-else class="gl-flex gl-items-center gl-justify-center gl-gap-3 gl-text-center">
              <gl-animated-upload-icon :is-on="animateUploadIcon" />
              <span>{{ __('Drop or upload file to attach') }}</span>
            </div>
            <input
              ref="fileUpload"
              type="file"
              name="file"
              hidden
              :accept="$options.validFileMimetypes"
              required
              :multiple="false"
              data-testid="dropzone-input"
              @change="setFile"
            />
          </button>
        </gl-form-group>
      </template>
      <template #back>
        <gl-button
          category="primary"
          variant="default"
          :href="backButtonPath"
          data-testid="back-button"
        >
          {{ __('Go back') }}
        </gl-button>
      </template>
      <template #next>
        <gl-button
          type="submit"
          category="primary"
          variant="confirm"
          data-testid="next-button"
          @click.prevent="onSubmit"
        >
          {{ __('Import project') }}
        </gl-button>
      </template>
    </multi-step-form-template>
  </form>
</template>
