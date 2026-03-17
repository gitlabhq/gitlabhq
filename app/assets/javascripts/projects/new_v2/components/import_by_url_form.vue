<script>
import {
  GlButton,
  GlForm,
  GlFormCheckbox,
  GlFormGroup,
  GlFormInput,
  GlFormInputGroup,
  GlLink,
  GlMultiStepFormTemplate,
} from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';
import { visitUrl, isReasonableGitUrl } from '~/lib/utils/url_utility';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { s__, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import SharedProjectCreationFields from './shared_project_creation_fields.vue';
import { checkRepositoryConnection } from './utils';

export default {
  components: {
    SharedProjectCreationFields,
    GlButton,
    GlForm,
    GlFormCheckbox,
    GlFormGroup,
    GlFormInput,
    GlFormInputGroup,
    GlLink,
    GlMultiStepFormTemplate,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    importByUrlValidatePath: {
      default: null,
    },
    hasRepositoryMirrorsFeature: {
      default: false,
    },
    newProjectPath: {
      default: null,
    },
    newProjectFormPath: {
      default: null,
    },
  },
  props: {
    namespace: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },

  data() {
    return {
      repositoryUrl: '',
      repositoryUsername: '',
      repositoryPassword: '',
      repositoryMirror: false,
      isCheckingConnection: false,
      urlValidationState: null,
    };
  },
  computed: {
    isImportByUrlNewPage() {
      return this.glFeatures.importByUrlNewPage;
    },
    currentStep() {
      return this.isImportByUrlNewPage ? null : 3;
    },
  },
  methods: {
    async checkConnection() {
      this.isCheckingConnection = true;

      const result = await checkRepositoryConnection(this.importByUrlValidatePath, {
        url: this.repositoryUrl,
        user: this.repositoryUsername,
        password: this.repositoryPassword,
      });

      if (!result.isValid) {
        this.isCheckingConnection = false;
        this.urlValidationState = false;
        return;
      }

      const message = result.success
        ? s__('ProjectImportByURL|Connection successful.')
        : sprintf(s__('ProjectImportByURL|Connection failed: %{error}'), { error: result.message });

      this.$toast.show(message);
      this.isCheckingConnection = false;
    },
    onSelectNamespace(newNamespace) {
      this.$emit('onSelectNamespace', newNamespace);
    },
    onBack() {
      if (this.isImportByUrlNewPage) {
        visitUrl(this.newProjectPath);
      } else {
        this.$emit('back');
      }
    },
    onBlur() {
      // Only validate on blur if there's actually content
      if (this.repositoryUrl.trim() === '') {
        this.urlValidationState = null;
      } else {
        this.urlValidationState = isReasonableGitUrl(this.repositoryUrl);
      }
    },
    onInput() {
      this.urlValidationState = null;
    },
  },
  csrf,
  repositoryUrlPlaceholder: 'https://gitlab.company.com/group/project.git',
  repositoryMirrorHelpPath: helpPagePath('user/project/repository/mirror/pull.md', {
    anchor: 'how-pull-mirroring-works',
  }),
};
</script>

<template>
  <gl-form method="post" :action="newProjectFormPath">
    <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
    <gl-multi-step-form-template
      :title="s__('ProjectImportByURL|Import repository by URL')"
      :current-step="currentStep"
    >
      <template #default>
        <gl-form-group
          :label="__('Git repository URL')"
          label-for="repository-url"
          :invalid-feedback="s__('ProjectImportByURL|Enter a valid URL')"
          :state="urlValidationState"
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
              :state="urlValidationState"
              :placeholder="$options.repositoryUrlPlaceholder"
              @blur="onBlur"
              @input="onInput"
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

        <gl-form-group :label="__('Mirror repository')" label-for="repository-mirror">
          <gl-form-checkbox
            id="repository-mirror"
            v-model="repositoryMirror"
            name="project[mirror]"
            :disabled="!hasRepositoryMirrorsFeature"
            data-testid="import-project-by-url-repo-mirror"
          >
            {{
              __(
                "Automatically update this project's branches and tags from the upstream repository.",
              )
            }}
            <gl-link :href="$options.repositoryMirrorHelpPath" target="_blank">
              {{ __('How does pull mirroring work?') }}
            </gl-link>
          </gl-form-checkbox>
        </gl-form-group>

        <shared-project-creation-fields
          :namespace="namespace"
          @onSelectNamespace="onSelectNamespace"
        />
      </template>

      <template #next>
        <gl-button
          v-if="isImportByUrlNewPage"
          type="submit"
          category="primary"
          variant="confirm"
          data-testid="import-project-by-url-next-button"
        >
          {{ __('Create project') }}
        </gl-button>
        <gl-button
          v-else
          category="primary"
          variant="confirm"
          :disabled="true"
          data-testid="import-project-by-url-next-button"
        >
          {{ __('Next step') }}
        </gl-button>
      </template>
      <template #back>
        <gl-button
          category="primary"
          variant="default"
          data-testid="import-project-by-url-back-button"
          @click="onBack"
        >
          {{ __('Go back') }}
        </gl-button>
      </template>
    </gl-multi-step-form-template>
  </gl-form>
</template>
