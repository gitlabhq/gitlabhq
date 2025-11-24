<script>
import {
  GlFormGroup,
  GlButton,
  GlSprintf,
  GlFormInput,
  GlFormInputGroup,
  GlLink,
} from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import csrf from '~/lib/utils/csrf';
import { s__, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';
import { isReasonableGitUrl } from '~/lib/utils/url_utility';
import SharedProjectCreationFields from './shared_project_creation_fields.vue';

export default {
  components: {
    GlFormGroup,
    GlButton,
    GlSprintf,
    GlFormInput,
    GlFormInputGroup,
    GlLink,
    MultiStepFormTemplate,
    SharedProjectCreationFields,
  },
  inject: {
    formPath: {
      default: null,
    },
    importByUrlValidatePath: {
      default: null,
    },
    importGithubImportPath: {
      default: null,
    },
  },
  props: {
    option: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    namespace: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      repositoryUrl: '',
      repositoryUsername: '',
      repositoryPassword: '',
      isRepositoryUrlValid: null,
      isCheckingConnection: false,
      isFormValid: false,
    };
  },
  methods: {
    async checkConnection() {
      this.isRepositoryUrlValid = isReasonableGitUrl(this.repositoryUrl);
      if (!this.isRepositoryUrlValid) return;

      this.isCheckingConnection = true;
      try {
        const { data } = await axios.post(this.importByUrlValidatePath, {
          url: this.repositoryUrl,
          user: this.repositoryUsername,
          password: this.repositoryPassword,
        });

        if (data.success) {
          this.$toast.show(s__('ProjectImportByURL|Connection successful.'));
        } else {
          this.$toast.show(
            sprintf(s__('ProjectImportByURL|Connection failed: %{error}'), { error: data.message }),
          );
        }
      } catch (error) {
        this.$toast.show(s__('ProjectImportByURL|Connection failed'));
      } finally {
        this.isCheckingConnection = false;
      }
    },
    onSelectNamespace(newNamespace) {
      this.$emit('onSelectNamespace', newNamespace);
    },
    onValidateSharedFields(status) {
      this.isFormValid = status;
    },
    onSubmit() {
      if (this.isFormValid) {
        this.$refs.form.submit();
      }
      return false;
    },
  },
  csrf,
  helpPagePath: helpPagePath('user/project/integrations/github.md'),
  repositoryUrlPlaceholder: 'https://gitlab.company.com/group/project.git',
};
</script>

<template>
  <form ref="form" method="post" :action="formPath" @submit.prevent="onSubmit">
    <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
    <multi-step-form-template :title="option.title" :current-step="2" :steps-total="2">
      <template #form>
        <p>
          {{
            __(
              'Connect your external repositories, and CI/CD pipelines will run for new commits. A GitLab project will be created with only CI/CD features enabled.',
            )
          }}
        </p>

        <div class="gl-border-t gl-my-6 gl-w-full"></div>

        <p>
          <gl-sprintf
            :message="
              __(
                'If using GitHub, you’ll see pipeline statuses on GitHub for your commits and pull requests. %{linkStart}More info%{linkEnd}',
              )
            "
          >
            <template #link="{ content }">
              <gl-link :href="$options.helpPagePath">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </p>

        <gl-button
          icon="github"
          data-testid="connect-github-project-button"
          :href="importGithubImportPath"
        >
          {{ s__('ImportButtons|Connect repositories from GitHub') }}
        </gl-button>

        <div class="gl-my-6 gl-flex gl-items-center gl-gap-4">
          <div class="gl-border-t gl-w-full"></div>
          <div class="gl-text-default">{{ __('or') }}</div>
          <div class="gl-border-t gl-w-full"></div>
        </div>

        <gl-form-group
          :label="__('Git repository URL')"
          label-for="repository-url"
          :invalid-feedback="s__('ProjectImportByURL|Enter a valid URL')"
          :state="isRepositoryUrlValid"
          data-testid="repository-url-form-group"
          :label-description="
            s__(
              'ProjectImportByURL|The repository must be accessible over http://, https:// or git://',
            )
          "
        >
          <gl-form-input-group>
            <gl-form-input
              id="repository-url"
              v-model="repositoryUrl"
              name="project[import_url]"
              autocomplete="off"
              data-testid="repository-url"
              type="url"
              required
              :state="isRepositoryUrlValid"
              :placeholder="$options.repositoryUrlPlaceholder"
            />
            <template #append>
              <gl-button
                :loading="isCheckingConnection"
                data-testid="check-connection"
                @click="checkConnection"
              >
                {{ s__('ProjectImportByURL|Check connection') }}
              </gl-button>
            </template>
          </gl-form-input-group>
        </gl-form-group>

        <div class="gl-grid gl-grid-cols-2 gl-gap-5">
          <gl-form-group :label="__('Username (optional)')" label-for="repository-username">
            <gl-form-input
              id="repository-username"
              v-model="repositoryUsername"
              name="project[import_url_user]"
              data-testid="repository-username"
              autocomplete="off"
            />
          </gl-form-group>

          <gl-form-group :label="__('Password (optional)')" label-for="repository-password">
            <gl-form-input
              id="repository-password"
              v-model="repositoryPassword"
              name="project[import_url_password]"
              data-testid="repository-password"
              type="password"
              autocomplete="off"
            />
          </gl-form-group>
        </div>

        <shared-project-creation-fields
          :namespace="namespace"
          @onSelectNamespace="onSelectNamespace"
          @onValidateForm="onValidateSharedFields"
        />
      </template>
      <template #next>
        <gl-button
          category="primary"
          variant="confirm"
          type="submit"
          :disabled="!isFormValid"
          data-testid="create-cicd-project-button"
        >
          {{ __('Create project') }}
        </gl-button>
      </template>
      <template #back>
        <gl-button
          category="primary"
          variant="default"
          data-testid="create-cicd-project-back-button"
          @click="$emit('back')"
        >
          {{ __('Go back') }}
        </gl-button>
      </template>
    </multi-step-form-template>
  </form>
</template>
