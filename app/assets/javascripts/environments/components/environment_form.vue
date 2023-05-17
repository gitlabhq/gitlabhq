<script>
import { GlButton, GlForm, GlFormGroup, GlFormInput, GlLink, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { isAbsolute } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import {
  ENVIRONMENT_NEW_HELP_TEXT,
  ENVIRONMENT_EDIT_HELP_TEXT,
} from 'ee_else_ce/environments/constants';

export default {
  components: {
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlLink,
    GlSprintf,
  },
  inject: { protectedEnvironmentSettingsPath: { default: '' } },
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
    loading: {
      required: false,
      type: Boolean,
      default: false,
    },
  },
  i18n: {
    header: __('Environments'),
    helpNewMessage: ENVIRONMENT_NEW_HELP_TEXT,
    helpEditMessage: ENVIRONMENT_EDIT_HELP_TEXT,
    nameLabel: __('Name'),
    nameFeedback: __('This field is required'),
    nameDisabledHelp: __("You cannot rename an environment after it's created."),
    nameDisabledLinkText: __('How do I rename an environment?'),
    urlLabel: __('External URL'),
    urlFeedback: __('The URL should start with http:// or https://'),
    save: __('Save'),
    cancel: __('Cancel'),
  },
  helpPagePath: helpPagePath('ci/environments/index.md'),
  renamingDisabledHelpPagePath: helpPagePath('ci/environments/index.md', {
    anchor: 'rename-an-environment',
  }),
  data() {
    return {
      visited: {
        name: null,
        url: null,
      },
    };
  },
  computed: {
    isNameDisabled() {
      return Boolean(this.environment.id);
    },
    showEditHelp() {
      return this.isNameDisabled && Boolean(this.protectedEnvironmentSettingsPath);
    },
    valid() {
      return {
        name: this.visited.name && this.environment.name !== '',
        url: this.visited.url && isAbsolute(this.environment.externalUrl),
      };
    },
  },
  methods: {
    onChange(env) {
      this.$emit('change', env);
    },
    visit(field) {
      this.visited[field] = true;
    },
  },
};
</script>
<template>
  <div>
    <h1 class="page-title gl-font-size-h-display">
      {{ title }}
    </h1>
    <div class="row col-12">
      <h4 class="gl-mt-0">
        {{ $options.i18n.header }}
      </h4>
      <p class="gl-w-full">
        <gl-sprintf
          :message="showEditHelp ? $options.i18n.helpEditMessage : $options.i18n.helpNewMessage"
        >
          <template #link="{ content }">
            <gl-link
              :href="showEditHelp ? protectedEnvironmentSettingsPath : $options.helpPagePath"
              >{{ content }}</gl-link
            >
          </template>
        </gl-sprintf>
      </p>
      <gl-form
        id="new_environment"
        :aria-label="title"
        class="gl-w-full"
        @submit.prevent="$emit('submit')"
      >
        <gl-form-group
          :label="$options.i18n.nameLabel"
          label-for="environment_name"
          :state="valid.name"
          :invalid-feedback="$options.i18n.nameFeedback"
        >
          <template v-if="isNameDisabled" #description>
            {{ $options.i18n.nameDisabledHelp }}
            <gl-link :href="$options.renamingDisabledHelpPagePath" target="_blank">
              {{ $options.i18n.nameDisabledLinkText }}
            </gl-link>
          </template>
          <gl-form-input
            id="environment_name"
            :value="environment.name"
            :state="valid.name"
            :disabled="isNameDisabled"
            name="environment[name]"
            required
            @input="onChange({ ...environment, name: $event })"
            @blur="visit('name')"
          />
        </gl-form-group>
        <gl-form-group
          :label="$options.i18n.urlLabel"
          :state="valid.url"
          :invalid-feedback="$options.i18n.urlFeedback"
          label-for="environment_external_url"
        >
          <gl-form-input
            id="environment_external_url"
            :value="environment.externalUrl"
            :state="valid.url"
            name="environment[external_url]"
            type="url"
            @input="onChange({ ...environment, externalUrl: $event })"
            @blur="visit('url')"
          />
        </gl-form-group>

        <div class="gl-mr-6">
          <gl-button
            :loading="loading"
            type="submit"
            variant="confirm"
            name="commit"
            class="js-no-auto-disable"
            >{{ $options.i18n.save }}</gl-button
          >
          <gl-button :href="cancelPath">{{ $options.i18n.cancel }}</gl-button>
        </div>
      </gl-form>
    </div>
  </div>
</template>
