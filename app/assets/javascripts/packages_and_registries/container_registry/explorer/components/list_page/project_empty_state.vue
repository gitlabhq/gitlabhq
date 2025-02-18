<script>
import { GlEmptyState, GlSprintf, GlLink, GlFormInputGroup, GlFormInput } from '@gitlab/ui';
import { s__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import {
  COPY_LOGIN_TITLE,
  COPY_BUILD_TITLE,
  COPY_PUSH_TITLE,
  QUICK_START,
} from '../../constants/index';

export default {
  name: 'ProjectEmptyState',
  components: {
    ClipboardButton,
    GlEmptyState,
    GlSprintf,
    GlLink,
    GlFormInputGroup,
    GlFormInput,
  },
  inject: ['config', 'dockerBuildCommand', 'dockerPushCommand', 'dockerLoginCommand'],
  i18n: {
    quickStart: QUICK_START,
    copyLoginTitle: COPY_LOGIN_TITLE,
    copyBuildTitle: COPY_BUILD_TITLE,
    copyPushTitle: COPY_PUSH_TITLE,
    introText: s__(
      `ContainerRegistry|With the Container Registry, every project can have its own space to store its Docker images. %{docLinkStart}More Information%{docLinkEnd}`,
    ),
    notLoggedInMessage: s__(
      `ContainerRegistry|If you are not already logged in, you need to authenticate to the Container Registry by using your GitLab username and password. If you have %{twofaDocLinkStart}Two-Factor Authentication%{twofaDocLinkEnd} enabled, use a %{personalAccessTokensDocLinkStart}personal access token%{personalAccessTokensDocLinkEnd} instead of a password.`,
    ),
    addImageText: s__(
      'ContainerRegistry|You can add an image to this registry with the following commands:',
    ),
  },
  containerRegistryHelpUrl: helpPagePath('user/packages/container_registry/_index'),
  twoFactorAuthHelpUrl: helpPagePath('user/profile/account/two_factor_authentication'),
  personalAccessTokensHelpUrl: helpPagePath('user/profile/personal_access_tokens'),
};
</script>
<template>
  <gl-empty-state
    :title="s__('ContainerRegistry|There are no container images stored for this project')"
    :svg-path="config.noContainersImage"
    :svg-height="null"
  >
    <template #description>
      <p data-testid="project-empty-state-intro">
        <gl-sprintf :message="$options.i18n.introText">
          <template #docLink="{ content }">
            <gl-link :href="$options.containerRegistryHelpUrl" target="_blank">{{
              content
            }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
      <h5>{{ $options.i18n.quickStart }}</h5>
      <p data-testid="project-empty-state-authentication">
        <gl-sprintf :message="$options.i18n.notLoggedInMessage">
          <template #twofaDocLink="{ content }">
            <gl-link :href="$options.twoFactorAuthHelpUrl" target="_blank">{{ content }}</gl-link>
          </template>
          <template #personalAccessTokensDocLink="{ content }">
            <gl-link :href="$options.personalAccessTokensHelpUrl" target="_blank">{{
              content
            }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
      <gl-form-input-group class="gl-mb-4">
        <gl-form-input
          :value="dockerLoginCommand"
          readonly
          type="text"
          :aria-label="s__('ContainerRegistry|Docker login command')"
          class="!gl-font-monospace"
        />
        <template #append>
          <clipboard-button
            :text="dockerLoginCommand"
            :title="$options.i18n.copyLoginTitle"
            class="!gl-m-0"
          />
        </template>
      </gl-form-input-group>
      <p class="gl-mb-4">
        {{ $options.i18n.addImageText }}
      </p>
      <gl-form-input-group class="gl-mb-4">
        <gl-form-input
          :value="dockerBuildCommand"
          readonly
          type="text"
          :aria-label="s__('ContainerRegistry|Docker build command')"
          class="!gl-font-monospace"
        />
        <template #append>
          <clipboard-button
            :text="dockerBuildCommand"
            :title="$options.i18n.copyBuildTitle"
            class="!gl-m-0"
          />
        </template>
      </gl-form-input-group>
      <gl-form-input-group>
        <gl-form-input
          :value="dockerPushCommand"
          readonly
          type="text"
          :aria-label="s__('ContainerRegistry|Docker push command')"
          class="!gl-font-monospace"
        />
        <template #append>
          <clipboard-button
            :text="dockerPushCommand"
            :title="$options.i18n.copyPushTitle"
            class="!gl-m-0"
          />
        </template>
      </gl-form-input-group>
    </template>
  </gl-empty-state>
</template>
