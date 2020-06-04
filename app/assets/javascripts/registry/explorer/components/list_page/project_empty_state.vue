<script>
import { GlEmptyState, GlSprintf, GlLink } from '@gitlab/ui';
import { mapState, mapGetters } from 'vuex';
import { s__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
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
  },
  i18n: {
    quickStart: QUICK_START,
    copyLoginTitle: COPY_LOGIN_TITLE,
    copyBuildTitle: COPY_BUILD_TITLE,
    copyPushTitle: COPY_PUSH_TITLE,
    introText: s__(
      `ContainerRegistry|With the Container Registry, every project can have its own space to store its Docker images. %{docLinkStart}More Information%{docLinkEnd}`,
    ),
    notLoggedInMessage: s__(
      `ContainerRegistry|If you are not already logged in, you need to authenticate to the Container Registry by using your GitLab username and password. If you have %{twofaDocLinkStart}Two-Factor Authentication%{twofaDocLinkEnd} enabled, use a %{personalAccessTokensDocLinkStart}Personal Access Token%{personalAccessTokensDocLinkEnd} instead of a password.`,
    ),
    addImageText: s__(
      'ContainerRegistry|You can add an image to this registry with the following commands:',
    ),
  },
  computed: {
    ...mapState(['config']),
    ...mapGetters(['dockerBuildCommand', 'dockerPushCommand', 'dockerLoginCommand']),
  },
};
</script>
<template>
  <gl-empty-state
    :title="s__('ContainerRegistry|There are no container images stored for this project')"
    :svg-path="config.noContainersImage"
    class="container-message"
  >
    <template #description>
      <p class="js-no-container-images-text">
        <gl-sprintf :message="$options.i18n.introText">
          <template #docLink="{content}">
            <gl-link :href="config.helpPagePath" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
      <h5>{{ $options.i18n.quickStart }}</h5>
      <p class="js-not-logged-in-to-registry-text">
        <gl-sprintf :message="$options.i18n.notLoggedInMessage">
          <template #twofaDocLink="{content}">
            <gl-link :href="config.twoFactorAuthHelpLink" target="_blank">{{ content }}</gl-link>
          </template>
          <template #personalAccessTokensDocLink="{content}">
            <gl-link :href="config.personalAccessTokensHelpLink" target="_blank">{{
              content
            }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
      <div class="input-group append-bottom-10">
        <input :value="dockerLoginCommand" type="text" class="form-control monospace" readonly />
        <span class="input-group-append">
          <clipboard-button
            :text="dockerLoginCommand"
            :title="$options.i18n.copyLoginTitle"
            class="input-group-text"
          />
        </span>
      </div>
      <p></p>
      <p>
        {{ $options.i18n.addImageText }}
      </p>

      <div class="input-group append-bottom-10">
        <input :value="dockerBuildCommand" type="text" class="form-control monospace" readonly />
        <span class="input-group-append">
          <clipboard-button
            :text="dockerBuildCommand"
            :title="$options.i18n.copyBuildTitle"
            class="input-group-text"
          />
        </span>
      </div>

      <div class="input-group">
        <input :value="dockerPushCommand" type="text" class="form-control monospace" readonly />
        <span class="input-group-append">
          <clipboard-button
            :text="dockerPushCommand"
            :title="$options.i18n.copyPushTitle"
            class="input-group-text"
          />
        </span>
      </div>
    </template>
  </gl-empty-state>
</template>
