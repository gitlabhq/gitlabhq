<script>
import {
  GlButton,
  GlForm,
  GlFormCheckbox,
  GlFormGroup,
  GlFormInput,
  GlFormInputGroup,
  GlLink,
} from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import csrf from '~/lib/utils/csrf';
import { visitUrl } from '~/lib/utils/url_utility';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { s__, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';
import SharedProjectCreationFields from './shared_project_creation_fields.vue';

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
    MultiStepFormTemplate,
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
    };
  },
  computed: {
    isImportByUrlNewPage() {
      return this.glFeatures.importByUrlNewPage;
    },
    currentStep() {
      return this.isImportByUrlNewPage ? null : 3;
    },
    isEmptyRepositoryUrl() {
      return !this.repositoryUrl.trim();
    },
  },
  methods: {
    async checkConnection() {
      this.isCheckingConnection = true;
      try {
        const { data } = await axios.post(this.importByUrlValidatePath, {
          url: this.repositoryUrl,
          user: this.repositoryUsername,
          password: this.repositoryPassword,
        });

        if (data.success) {
          this.$toast.show(s__('Integrations|Connection successful.'));
        } else {
          this.$toast.show(
            sprintf(s__('ProjectImport|Connection failed: %{error}'), { error: data.message }),
          );
        }
      } catch (error) {
        this.$toast.show(sprintf(s__('ProjectImport|Connection failed: %{error}'), { error }));
      } finally {
        this.isCheckingConnection = false;
      }
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
    <multi-step-form-template
      :title="s__('ProjectImport|Import repository by URL')"
      :current-step="currentStep"
    >
      <template #form>
        <gl-form-group
          :label="__('Git repository URL')"
          label-for="repository-url"
          :label-description="
            s__('ProjectImport|The repository must be accessible over http://, https:// or git://')
          "
        >
          <gl-form-input-group>
            <gl-form-input
              id="repository-url"
              v-model="repositoryUrl"
              name="project[import_url]"
              autocomplete="off"
              data-testid="repository-url"
              :placeholder="$options.repositoryUrlPlaceholder"
            />
            <template #append>
              <gl-button
                :loading="isCheckingConnection"
                data-testid="check-connection"
                @click="checkConnection"
              >
                {{ s__('ProjectImport|Check connection') }}
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
          :disabled="isEmptyRepositoryUrl"
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
    </multi-step-form-template>
  </gl-form>
</template>
