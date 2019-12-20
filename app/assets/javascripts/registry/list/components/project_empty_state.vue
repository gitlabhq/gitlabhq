<script>
import { GlEmptyState } from '@gitlab/ui';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { s__, sprintf } from '~/locale';

export default {
  name: 'ProjectEmptyState',
  components: {
    ClipboardButton,
    GlEmptyState,
  },
  props: {
    noContainersImage: {
      type: String,
      required: true,
    },
    repositoryUrl: {
      type: String,
      required: true,
    },
    helpPagePath: {
      type: String,
      required: true,
    },
    twoFactorAuthHelpLink: {
      type: String,
      required: true,
    },
    personalAccessTokensHelpLink: {
      type: String,
      required: true,
    },
    registryHostUrlWithPort: {
      type: String,
      required: true,
    },
  },
  computed: {
    dockerBuildCommand() {
      // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
      return `docker build -t ${this.repositoryUrl} .`;
    },
    dockerPushCommand() {
      // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
      return `docker push ${this.repositoryUrl}`;
    },
    dockerLoginCommand() {
      // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
      return `docker login ${this.registryHostUrlWithPort}`;
    },
    noContainerImagesText() {
      return sprintf(
        s__(`ContainerRegistry|With the Container Registry, every project can have its own space to
            store its Docker images. %{docLinkStart}More Information%{docLinkEnd}`),
        {
          docLinkStart: `<a href="${this.helpPagePath}" target="_blank">`,
          docLinkEnd: '</a>',
        },
        false,
      );
    },
    notLoggedInToRegistryText() {
      return sprintf(
        s__(`ContainerRegistry|If you are not already logged in, you need to authenticate to
             the Container Registry by using your GitLab username and password. If you have
             %{twofaDocLinkStart}Two-Factor Authentication%{twofaDocLinkEnd} enabled, use a
             %{personalAccessTokensDocLinkStart}Personal Access Token%{personalAccessTokensDocLinkEnd}
            instead of a password.`),
        {
          twofaDocLinkStart: `<a href="${this.twoFactorAuthHelpLink}" target="_blank">`,
          twofaDocLinkEnd: '</a>',
          personalAccessTokensDocLinkStart: `<a href="${this.personalAccessTokensHelpLink}" target="_blank">`,
          personalAccessTokensDocLinkEnd: '</a>',
        },
        false,
      );
    },
  },
};
</script>
<template>
  <gl-empty-state
    :title="s__('ContainerRegistry|There are no container images stored for this project')"
    :svg-path="noContainersImage"
    class="container-message"
  >
    <template #description>
      <p class="js-no-container-images-text" v-html="noContainerImagesText"></p>
      <h5>{{ s__('ContainerRegistry|Quick Start') }}</h5>
      <p class="js-not-logged-in-to-registry-text" v-html="notLoggedInToRegistryText"></p>
      <div class="input-group append-bottom-10">
        <input :value="dockerLoginCommand" type="text" class="form-control monospace" readonly />
        <span class="input-group-append">
          <clipboard-button
            :text="dockerLoginCommand"
            :title="s__('ContainerRegistry|Copy login command')"
            class="input-group-text"
          />
        </span>
      </div>
      <p></p>
      <p>
        {{
          s__(
            'ContainerRegistry|You can add an image to this registry with the following commands:',
          )
        }}
      </p>

      <div class="input-group append-bottom-10">
        <input :value="dockerBuildCommand" type="text" class="form-control monospace" readonly />
        <span class="input-group-append">
          <clipboard-button
            :text="dockerBuildCommand"
            :title="s__('ContainerRegistry|Copy build command')"
            class="input-group-text"
          />
        </span>
      </div>

      <div class="input-group">
        <input :value="dockerPushCommand" type="text" class="form-control monospace" readonly />
        <span class="input-group-append">
          <clipboard-button
            :text="dockerPushCommand"
            :title="s__('ContainerRegistry|Copy push command')"
            class="input-group-text"
          />
        </span>
      </div>
    </template>
  </gl-empty-state>
</template>
