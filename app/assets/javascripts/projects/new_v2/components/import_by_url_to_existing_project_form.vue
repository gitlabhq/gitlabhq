<script>
import {
  GlAlert,
  GlButton,
  GlCard,
  GlForm,
  GlFormCheckbox,
  GlFormGroup,
  GlFormInput,
  GlFormInputGroup,
  GlLink,
} from '@gitlab/ui';
import { isReasonableGitUrl } from '~/lib/utils/url_utility';
import csrf from '~/lib/utils/csrf';
import { s__, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { checkRepositoryConnection } from './utils';

export default {
  name: 'ImportByUrlToExistingProjectForm',
  components: {
    GlAlert,
    GlCard,
    GlButton,
    GlForm,
    GlFormCheckbox,
    GlFormGroup,
    GlFormInput,
    GlFormInputGroup,
    GlLink,
  },
  inject: {
    importByUrlValidatePath: {
      default: null,
    },
    importFromUrl: {
      default: null,
    },
    importPath: {
      default: null,
    },
    gitTimeout: {
      default: null,
    },
    ciCdOnly: {
      default: false,
    },
    hasRepositoryMirrorsFeature: {
      default: false,
    },
  },
  data() {
    return {
      repositoryUrl: this.importFromUrl,
      repositoryUsername: '',
      repositoryPassword: '',
      repositoryMirror: false,
      isSubmitting: false,
      isCheckingConnection: false,
      urlValidationState: null,
      submissionError: false,
    };
  },
  computed: {
    timeoutMessage() {
      const action = this.ciCdOnly ? 'connection' : 'import';
      return sprintf(
        s__(
          `ProjectImportByURL|The %{action} will time out after %{timeout}. For repositories that take longer, use a clone/push combination instead of this form.`,
        ),
        { action, timeout: this.gitTimeout },
      );
    },
    svnMessage() {
      if (this.ciCdOnly) {
        return s__('ProjectImportByURL|Need to connect an SVN repository?');
      }
      return s__(
        'ProjectImportByURL|You can import a Subversion repository by using third-party tools.',
      );
    },
    invalidFeedbackMessage() {
      return s__('ProjectImportByURL|Enter a valid URL');
    },
  },
  methods: {
    async handleFormSubmit(e) {
      this.isSubmitting = true;

      const result = await checkRepositoryConnection(this.importByUrlValidatePath, {
        url: this.repositoryUrl,
        user: this.repositoryUsername,
        password: this.repositoryPassword,
      });

      if (!result.success) {
        this.submissionError = true;
        this.isSubmitting = false;
        return;
      }
      e.target.submit();
    },
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
    onBlur() {
      this.urlValidationState =
        this.repositoryUrl === '' ? null : isReasonableGitUrl(this.repositoryUrl);
    },
    onInput() {
      this.urlValidationState = null;
      this.submissionError = false;
    },
  },
  csrf,
  repositoryUrlPlaceholder: 'https://gitlab.company.com/group/project.git',
  repositoryMirrorHelpPath: helpPagePath('user/project/repository/mirror/pull.md', {
    anchor: 'how-pull-mirroring-works',
  }),
  subversionHelpPath: helpPagePath('user/import/_index.md', {
    anchor: 'migrate-from-subversion',
  }),
  sshMirrorHelpPath: helpPagePath('user/project/repository/mirror/_index.md', {
    anchor: 'ssh-authentication',
  }),
};
</script>

<template>
  <gl-form
    id="import-by-url-to-project-form"
    method="post"
    :action="importPath"
    novalidate
    @submit.prevent="handleFormSubmit"
  >
    <gl-alert
      v-if="submissionError"
      variant="danger"
      dismissible
      :dismiss-label="__('Dismiss')"
      class="gl-mb-4"
      data-testid="connection-error-alert"
      @dismiss="submissionError = false"
    >
      {{
        s__('ProjectImportByURL|Unable to access repository with the URL and credentials provided.')
      }}
    </gl-alert>
    <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
    <gl-card class="gl-my-7">
      <ul class="gl-mb-1 gl-mt-3">
        <li>
          {{
            s__(
              'ProjectImportByURL|When using the http:// or https:// protocols, please provide the exact URL to the repository. HTTP redirects will not be followed.',
            )
          }}
        </li>
        <li>
          {{
            s__(
              'ProjectImportByURL|If your HTTP repository is not publicly accessible, add your credentials.',
            )
          }}
        </li>
        <li v-if="gitTimeout">{{ timeoutMessage }}</li>
        <li>
          {{ svnMessage }}
          <gl-link :href="$options.subversionHelpPath" target="_blank">
            {{ __('Learn more.') }}
          </gl-link>
        </li>
        <li v-if="!ciCdOnly">
          {{ s__('ProjectImportByURL|Once imported, repositories can be mirrored over SSH.') }}
          <gl-link :href="$options.sshMirrorHelpPath" target="_blank">
            {{ __('Learn more.') }}
          </gl-link>
        </li>
      </ul>
    </gl-card>
    <gl-form-group
      class="gl-mt-6"
      :label="__('Git repository URL')"
      label-for="project_import_url"
      :invalid-feedback="invalidFeedbackMessage"
      :state="urlValidationState"
      data-testid="repository-url-form-group"
      :label-description="
        s__('ProjectImportByURL|The repository must be accessible over http://, https:// or git://')
      "
    >
      <gl-form-input-group>
        <gl-form-input
          id="project_import_url"
          v-model.trim="repositoryUrl"
          name="project[import_url]"
          autocomplete="off"
          data-testid="project_import_url"
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
            :disabled="isCheckingConnection"
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

    <gl-form-group v-if="!ciCdOnly" :label="__('Mirror repository')" label-for="repository-mirror">
      <gl-form-checkbox
        id="repository-mirror"
        v-model="repositoryMirror"
        name="project[mirror]"
        :disabled="!hasRepositoryMirrorsFeature"
        data-testid="import-project-by-url-repo-mirror"
      >
        {{
          __("Automatically update this project's branches and tags from the upstream repository.")
        }}
        <gl-link :href="$options.repositoryMirrorHelpPath" target="_blank">
          {{ __('How does pull mirroring work?') }}
        </gl-link>
      </gl-form-checkbox>
    </gl-form-group>

    <gl-button
      type="submit"
      class="js-no-auto-disable"
      category="primary"
      variant="confirm"
      :loading="isSubmitting"
      :disabled="isSubmitting"
      >{{ s__('ProjectImportByURL|Start import') }}</gl-button
    >
  </gl-form>
</template>
