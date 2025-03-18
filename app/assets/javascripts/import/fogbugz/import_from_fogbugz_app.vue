<script>
import { GlButton, GlFormGroup, GlFormInput } from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';

export default {
  components: {
    GlButton,
    GlFormGroup,
    GlFormInput,
    MultiStepFormTemplate,
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
  csrf,
};
</script>

<template>
  <form method="post" :action="formPath">
    <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
    <multi-step-form-template
      :title="s__('ProjectsNew|Import projects from FogBugz')"
      :current-step="3"
      :steps-total="4"
    >
      <template #form>
        <gl-form-group :label="s__('ProjectsNew|FogBugz URL')" label-for="uri">
          <gl-form-input
            id="uri"
            name="uri"
            required
            :placeholder="s__('ProjectsNew|https://mycompany.fogbugz.com')"
          />
        </gl-form-group>
        <gl-form-group :label="__('Email')" label-for="email">
          <gl-form-input id="email" name="email" required :placeholder="__('Your email')" />
        </gl-form-group>
        <gl-form-group :label="__('Password')" label-for="password">
          <gl-form-input
            id="password"
            name="password"
            required
            type="password"
            :placeholder="__('Your password')"
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
        <gl-button type="submit" category="primary" variant="confirm" data-testid="next-button">
          {{ __('Next step') }}
        </gl-button>
      </template>
    </multi-step-form-template>
  </form>
</template>
