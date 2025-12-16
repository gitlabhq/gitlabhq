<script>
import { GlButton, GlFormGroup, GlFormInput, GlAlert, GlSprintf, GlLink, GlIcon } from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';
import SafeHtml from '~/vue_shared/directives/safe_html';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';

export default {
  components: {
    GlButton,
    GlFormGroup,
    GlFormInput,
    GlAlert,
    GlSprintf,
    GlLink,
    GlIcon,
    MultiStepFormTemplate,
  },
  directives: {
    SafeHtml,
  },
  inject: {
    backButtonPath: {
      type: String,
      required: true,
    },
    namespaceId: {
      type: String,
      required: false,
      default: null,
    },
    messageAdmin: {
      type: String,
      required: false,
      default: '',
    },
    isCiCdOnly: {
      type: Boolean,
      required: true,
    },
    isConfigured: {
      type: Boolean,
      required: true,
    },
    buttonAuthHref: {
      type: String,
      required: false,
      default: '',
    },
    formPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    showAuthButton() {
      return !this.isCiCdOnly && this.isConfigured;
    },
    showAdminMessage() {
      return !this.isCiCdOnly && !this.isConfigured;
    },
  },
  csrf,
  placeholders: {
    token: '8d3f016698e...',
  },
};
</script>

<template>
  <form method="post" :action="formPath">
    <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
    <input
      id="namespace_id"
      type="hidden"
      name="namespace_id"
      autocomplete="off"
      :value="namespaceId"
    />
    <input v-if="isCiCdOnly" id="ci_cd_only" type="hidden" name="ci_cd_only" value="true" />
    <multi-step-form-template
      :title="s__('ProjectsNew|Authenticate with GitHub')"
      :current-step="3"
      :steps-total="4"
    >
      <template #form>
        <template v-if="showAuthButton">
          <gl-button
            category="primary"
            variant="confirm"
            icon="github"
            :href="buttonAuthHref"
            data-testid="github-auth-button"
          >
            {{ s__('ProjectsNew|Authenticate through GitHub') }}
          </gl-button>
          <div class="gl-my-6 gl-flex gl-items-center gl-gap-4">
            <div class="gl-border-t gl-w-full"></div>
            <div class="gl-text-default">{{ __('or') }}</div>
            <div class="gl-border-t gl-w-full"></div>
          </div>
        </template>

        <gl-alert v-if="showAdminMessage" class="gl-mb-5" :dismissible="false">
          <span v-safe-html="messageAdmin"></span>
        </gl-alert>

        <gl-form-group :label="__('Use personal access token')" label-for="personal_access_token">
          <gl-form-input
            id="personal_access_token"
            name="personal_access_token"
            type="password"
            required
            :placeholder="$options.placeholders.token"
          />
          <template #description>
            <p class="gl-mb-3">
              <gl-sprintf
                :message="
                  s__(
                    'GithubImport|Create and provide your GitHub %{linkStart}personal access token%{linkEnd}.',
                  )
                "
              >
                <template #link="{ content }">
                  <gl-link href="https://github.com/settings/tokens" target="_blank">{{
                    content
                  }}</gl-link>
                </template>
              </gl-sprintf>
            </p>
            <p class="gl-mb-3">
              {{
                s__(
                  'GithubImport|Use a classic GitHub personal access token with the following scopes:',
                )
              }}
            </p>
            <ul>
              <li v-if="isCiCdOnly" class="gl-mb-3">
                <gl-sprintf
                  :message="
                    s__(
                      'GithubImporter|%{codeStart}repo%{codeEnd}: Used to display a list of your public and private repositories that are available to connect to.',
                    )
                  "
                >
                  <template #code="{ content }">
                    <code>{{ content }}</code>
                  </template>
                </gl-sprintf>
              </li>
              <li v-if="!isCiCdOnly" class="gl-mb-3">
                <gl-sprintf
                  :message="
                    s__(
                      'GithubImporter|%{codeStart}repo%{codeEnd}: Used to display a list of your public and private repositories that are available to import from.',
                    )
                  "
                >
                  <template #code="{ content }">
                    <code>{{ content }}</code>
                  </template>
                </gl-sprintf>
              </li>
              <li v-if="!isCiCdOnly" class="gl-mb-3">
                <gl-sprintf
                  :message="
                    s__(
                      'GithubImporter|%{codeStart}read:org%{codeEnd} (optional): Used to import collaborators from GitHub repositories, or if your project has Git LFS files.',
                    )
                  "
                >
                  <template #code="{ content }">
                    <code>{{ content }}</code>
                  </template>
                </gl-sprintf>
              </li>
            </ul>
            <gl-sprintf :message="s__('GithubImport|%{linkStart}Learn more%{linkEnd}.')">
              <template #link="{ content }">
                <gl-link
                  href="https://github.com/settings/tokens#use-a-github-personal-access-token"
                  target="_blank"
                >
                  {{ content }}
                  <gl-icon name="external-link" :aria-label="__('(external link)')" />
                </gl-link>
              </template>
            </gl-sprintf>
          </template>
        </gl-form-group>
      </template>
      <template #back>
        <gl-button category="primary" variant="default" :href="backButtonPath">
          {{ __('Go back') }}
        </gl-button>
      </template>
      <template #next>
        <gl-button type="submit" category="primary" variant="confirm">
          {{ __('Next step') }}
        </gl-button>
      </template>
    </multi-step-form-template>
  </form>
</template>
