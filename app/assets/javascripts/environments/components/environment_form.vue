<script>
import { GlButton, GlForm, GlFormGroup, GlFormInput, GlLink, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { isAbsolute } from '~/lib/utils/url_utility';
import { __ } from '~/locale';

export default {
  components: {
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlLink,
    GlSprintf,
  },
  props: {
    environment: {
      required: true,
      type: Object,
    },
    title: {
      required: true,
      type: String,
    },
    cancelPath: {
      required: true,
      type: String,
    },
  },
  i18n: {
    header: __('Environments'),
    helpMessage: __(
      'Environments allow you to track deployments of your application. %{linkStart}More information%{linkEnd}.',
    ),
    nameLabel: __('Name'),
    nameFeedback: __('This field is required'),
    urlLabel: __('External URL'),
    urlFeedback: __('The URL should start with http:// or https://'),
    save: __('Save'),
    cancel: __('Cancel'),
  },
  helpPagePath: helpPagePath('ci/environments/index.md'),
  data() {
    return {
      errors: {
        name: null,
        url: null,
      },
    };
  },
  methods: {
    onChange(env) {
      this.$emit('change', env);
    },
    validateUrl() {
      this.errors.url = isAbsolute(this.environment.externalUrl);
    },
    validateName() {
      this.errors.name = this.environment.name !== '';
    },
  },
};
</script>
<template>
  <div>
    <h3 class="page-title">
      {{ title }}
    </h3>
    <hr />
    <div class="row gl-mt-3 gl-mb-3">
      <div class="col-lg-3">
        <h4 class="gl-mt-0">
          {{ $options.i18n.header }}
        </h4>
        <p>
          <gl-sprintf :message="$options.i18n.helpMessage">
            <template #link="{ content }">
              <gl-link :href="$options.helpPagePath">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </p>
      </div>
      <gl-form
        id="new_environment"
        :aria-label="title"
        class="col-lg-9"
        @submit.prevent="$emit('submit')"
      >
        <gl-form-group
          :label="$options.i18n.nameLabel"
          label-for="environment_name"
          :state="errors.name"
          :invalid-feedback="$options.i18n.nameFeedback"
        >
          <gl-form-input
            id="environment_name"
            :value="environment.name"
            :state="errors.name"
            name="environment[name]"
            required
            @input="onChange({ ...environment, name: $event })"
            @blur="validateName"
          />
        </gl-form-group>
        <gl-form-group
          :label="$options.i18n.urlLabel"
          :state="errors.url"
          :invalid-feedback="$options.i18n.urlFeedback"
          label-for="environment_external_url"
        >
          <gl-form-input
            id="environment_external_url"
            :value="environment.externalUrl"
            :state="errors.url"
            name="environment[external_url]"
            type="url"
            @input="onChange({ ...environment, externalUrl: $event })"
            @blur="validateUrl"
          />
        </gl-form-group>

        <div class="form-actions">
          <gl-button type="submit" variant="confirm" name="commit" class="js-no-auto-disable">{{
            $options.i18n.save
          }}</gl-button>
          <gl-button :href="cancelPath">{{ $options.i18n.cancel }}</gl-button>
        </div>
      </gl-form>
    </div>
  </div>
</template>
