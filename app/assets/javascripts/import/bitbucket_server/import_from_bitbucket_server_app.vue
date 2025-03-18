<script>
import { GlButton, GlFormGroup, GlFormInput } from '@gitlab/ui';
import validation, { initForm } from '~/vue_shared/directives/validation';
import csrf from '~/lib/utils/csrf';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';

export default {
  components: {
    GlButton,
    GlFormGroup,
    GlFormInput,
    MultiStepFormTemplate,
  },
  directives: {
    validation: validation(),
  },
  props: {
    backButtonPath: {
      type: String,
      required: true,
    },
    formPath: {
      type: String,
      required: true,
    },
  },
  data() {
    const form = initForm({
      fields: {
        bitbucket_server_url: { value: null },
        bitbucket_server_username: { value: null },
        personal_access_token: { value: null },
      },
    });
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
    url: 'https://your-bitbucket-server.com',
    token: '8d3f016698e...',
    username: 'username',
  },
};
</script>

<template>
  <form ref="form" method="post" :action="formPath" @submit.prevent="onSubmit">
    <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
    <multi-step-form-template
      :title="s__('ProjectsNew|Import repositories from Bitbucket Server')"
      :current-step="3"
      :steps-total="4"
    >
      <template #form>
        <gl-form-group
          :label="s__('ProjectsNew|Bitbucket Server URL')"
          label-for="bitbucket_server_url"
          :invalid-feedback="form.fields.bitbucket_server_url.feedback"
          data-testid="url-group"
        >
          <gl-form-input
            id="bitbucket_server_url"
            v-model="form.fields.bitbucket_server_url.value"
            v-validation:[form.showValidation]
            :validation-message="s__('ProjectsNew|Please enter a valid Bitbucket Server URL.')"
            :state="form.fields.bitbucket_server_url.state"
            name="bitbucket_server_url"
            type="url"
            required
            :placeholder="$options.placeholders.url"
            data-testid="url-input"
          />
        </gl-form-group>
        <gl-form-group
          :label="__('Username')"
          label-for="bitbucket_server_username"
          :invalid-feedback="form.fields.bitbucket_server_username.feedback"
          data-testid="username-group"
        >
          <gl-form-input
            id="bitbucket_server_username"
            v-model="form.fields.bitbucket_server_username.value"
            v-validation:[form.showValidation]
            :validation-message="s__('ProjectsNew|Please enter a valid username.')"
            :state="form.fields.bitbucket_server_username.state"
            name="bitbucket_server_username"
            required
            :placeholder="$options.placeholders.username"
            data-testid="username-input"
          />
        </gl-form-group>
        <gl-form-group
          :label="s__('ProjectsNew|Password/Personal access token')"
          label-for="personal_access_token"
          :invalid-feedback="form.fields.personal_access_token.feedback"
          data-testid="token-group"
        >
          <gl-form-input
            id="personal_access_token"
            v-model="form.fields.personal_access_token.value"
            v-validation:[form.showValidation]
            :validation-message="s__('ProjectsNew|Please enter a valid token.')"
            :state="form.fields.personal_access_token.state"
            name="personal_access_token"
            required
            type="password"
            :placeholder="$options.placeholders.token"
            data-testid="token-input"
          />
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
