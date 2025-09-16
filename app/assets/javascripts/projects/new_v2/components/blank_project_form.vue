<script>
import { GlButton, GlFormGroup, GlSprintf, GlLink, GlExperimentBadge } from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';
import { helpPagePath } from '~/helpers/help_page_helper';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';
import MultipleChoiceSelector from '~/vue_shared/components/multiple_choice_selector.vue';
import MultipleChoiceSelectorItem from '~/vue_shared/components/multiple_choice_selector_item.vue';
import SharedProjectCreationFields from './shared_project_creation_fields.vue';

export default {
  components: {
    GlButton,
    GlFormGroup,
    GlSprintf,
    GlLink,
    GlExperimentBadge,
    MultiStepFormTemplate,
    MultipleChoiceSelector,
    MultipleChoiceSelectorItem,
    SharedProjectCreationFields,
  },
  inject: {
    displaySha256Repository: {
      default: false,
    },
    formPath: {
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
      configurationReadme: true,
      configurationSast: false,
      configurationSha256: false,
      isFormValid: false,
    };
  },
  methods: {
    onSelectNamespace(newNamespace) {
      this.$emit('onSelectNamespace', newNamespace);
    },
    onConfigurationChange(checked) {
      this.configurationReadme = checked.includes('readme');
      this.configurationSast = checked.includes('sast');
      this.configurationSha256 = checked.includes('sha256');
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
  helpPageSast: helpPagePath('user/application_security/sast/_index'),
  projectConfigurationDefaultOptions: ['readme'],
  csrf,
};
</script>

<template>
  <form ref="form" method="post" :action="formPath" @submit.prevent="onSubmit">
    <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
    <multi-step-form-template :title="option.title" :current-step="2" :steps-total="2">
      <template #form>
        <shared-project-creation-fields
          :namespace="namespace"
          @onSelectNamespace="onSelectNamespace"
          @onValidateForm="onValidateSharedFields"
        />

        <gl-form-group
          :label="s__('ProjectsNew|Project Configuration')"
          data-testid="configuration-form-group"
        >
          <multiple-choice-selector
            :checked="$options.projectConfigurationDefaultOptions"
            data-testid="configuration-selector"
            @input="onConfigurationChange"
          >
            <multiple-choice-selector-item
              value="readme"
              :title="s__('ProjectsNew|Initialize repository with a README')"
              data-testid="initialize-with-readme-checkbox"
            >
              <template #description>
                {{
                  s__(
                    'ProjectsNew|Allows you to immediately clone this project’s repository. Skip this if you plan to push up an existing repository.',
                  )
                }}
                <input
                  type="hidden"
                  name="project[initialize_with_readme]"
                  :value="configurationReadme"
                />
              </template>
            </multiple-choice-selector-item>
            <multiple-choice-selector-item
              value="sast"
              :title="s__('ProjectsNew|Enable Static Application Security Testing (SAST)')"
              data-testid="initialize-with-sast-checkbox"
            >
              <template #description>
                <p class="help-text">
                  <gl-sprintf
                    :message="
                      s__(
                        'ProjectsNew|Analyze your source code for known security vulnerabilities. %{linkStart}Learn more%{linkEnd}.',
                      )
                    "
                  >
                    <template #link="{ content }">
                      <gl-link :href="$options.helpPageSast">{{ content }}</gl-link>
                    </template>
                  </gl-sprintf>
                </p>
                <input
                  type="hidden"
                  name="project[initialize_with_sast]"
                  :value="configurationSast"
                />
              </template>
            </multiple-choice-selector-item>
            <multiple-choice-selector-item
              v-if="displaySha256Repository"
              value="sha256"
              :description="
                s__(
                  `ProjectsNew|Might break existing functionality with other repositories or APIs. It's not possible to change SHA-256 repositories back to the default SHA-1 hashing algorithm.`,
                )
              "
              data-testid="initialize-with-sha-256-checkbox"
            >
              {{ s__('ProjectsNew|Use SHA-256 for repository hashing algorithm') }}
              <gl-experiment-badge class="!gl-m-0" />
              <input
                type="hidden"
                name="project[use_sha256_repository]"
                :value="configurationSha256"
              />
            </multiple-choice-selector-item>
          </multiple-choice-selector>
        </gl-form-group>

        <!-- Two checkboxes from JiHu should be added here in: https://gitlab.com/gitlab-org/gitlab/-/issues/514700 -->
      </template>
      <template #next>
        <gl-button
          category="primary"
          variant="confirm"
          data-testid="create-project-button"
          type="submit"
          :disabled="!isFormValid"
        >
          {{ __('Create project') }}
        </gl-button>
      </template>
      <template #back>
        <gl-button
          category="primary"
          data-testid="create-project-back-button"
          variant="default"
          @click="$emit('back')"
        >
          {{ __('Go back') }}
        </gl-button>
      </template>
    </multi-step-form-template>
  </form>
</template>
