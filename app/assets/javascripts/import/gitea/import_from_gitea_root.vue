<script>
import { GlButton, GlFormGroup, GlFormInput, GlSprintf, GlLink } from '@gitlab/ui';
import validation from '~/vue_shared/directives/validation';
import csrf from '~/lib/utils/csrf';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';

const feedbackMap = {
  valueMissing: {
    isInvalid: (el) => el.validity?.valueMissing,
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
    GlSprintf,
    GlLink,
    MultiStepFormTemplate,
  },
  directives: {
    validation: validation(feedbackMap),
  },
  props: {
    backButtonPath: {
      type: String,
      required: true,
    },
    namespaceId: {
      type: String,
      required: false,
      default: null,
    },
    formPath: {
      type: String,
      required: true,
    },
  },
  data() {
    const form = {
      state: false,
      showValidation: false,
      fields: {
        gitea_host_url: initFormField(),
        personal_access_token: initFormField(),
      },
    };
    return {
      form,
    };
  },
  methods: {
    onSubmit() {
      if (!this.form.state) {
        this.form.showValidation = true;
        return;
      }

      this.$refs.form.submit();
    },
  },
  csrf,
  placeholders: {
    url: 'https://gitea.com',
    token: '8d3f016698e...',
  },
};
</script>

<template>
  <form ref="form" method="post" :action="formPath" @submit.prevent="onSubmit">
    <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
    <input type="hidden" name="namespace_id" autocomplete="off" :value="namespaceId" />
    <multi-step-form-template
      :title="s__('ProjectsNew|Import projects from Gitea')"
      :current-step="3"
      :steps-total="4"
    >
      <template #form>
        <gl-form-group
          :label="s__('ProjectsNew|Gitea host URL')"
          label-for="gitea_host_url"
          :invalid-feedback="form.fields.gitea_host_url.feedback"
          data-testid="gitea-host-url-group"
        >
          <gl-form-input
            id="gitea_host_url"
            v-model="form.fields.gitea_host_url.value"
            v-validation:[form.showValidation]
            :validation-message="s__('ProjectsNew|Please enter a valid Gitea host URL.')"
            :state="form.fields.gitea_host_url.state"
            required
            name="gitea_host_url"
            :placeholder="$options.placeholders.url"
            data-testid="gitea-host-url-input"
          />
        </gl-form-group>
        <gl-form-group
          :label="__('Personal access token')"
          label-for="personal_access_token"
          :invalid-feedback="form.fields.personal_access_token.feedback"
          data-testid="personal-access-token-group"
        >
          <gl-form-input
            id="personal_access_token"
            v-model="form.fields.personal_access_token.value"
            v-validation:[form.showValidation]
            :validation-message="s__('ProjectsNew|Please enter a valid personal access token.')"
            :state="form.fields.personal_access_token.state"
            required
            name="personal_access_token"
            type="password"
            :placeholder="$options.placeholders.token"
            data-testid="personal-access-token-input"
          />
          <template #description>
            <gl-sprintf
              :message="
                s__(
                  'GithubImport|Learn more about %{linkStart}Gitea personal access tokens%{linkEnd}.',
                )
              "
            >
              <template #link="{ content }">
                <gl-link
                  href="https://docs.gitea.io/en-us/api-usage/#authentication-via-the-api"
                  target="_blank"
                  >{{ content }}</gl-link
                >
              </template>
            </gl-sprintf>
          </template>
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
          {{ __('Next step') }}
        </gl-button>
      </template>
    </multi-step-form-template>
  </form>
</template>
