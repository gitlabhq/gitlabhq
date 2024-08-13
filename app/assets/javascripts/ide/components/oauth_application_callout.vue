<script>
import { GlAlert, GlSprintf } from '@gitlab/ui';

import { s__ } from '~/locale';
import ResetApplicationSettingsModal from './reset_application_settings_modal.vue';

export const I18N_WEB_IDE_OAUTH_APPLICATION_CALLOUT = {
  alertTitle: s__(
    'IDE|Editing this application might affect the functionality of the Web IDE. Ensure the configuration meets the following conditions:',
  ),
  alertButtonText: s__('IDE|Restore to default'),
  configurations: [
    s__(
      'IDE|The redirect URI path is %{codeBlockStart}%{pathFormat}%{codeBlockEnd}. An example of a valid redirect URI is %{codeBlockStart}%{example}%{codeBlockEnd}.',
    ),
    s__('IDE|The %{boldStart}Trusted%{boldEnd} checkbox is selected.'),
    s__('IDE|The %{boldStart}Confidential%{boldEnd} checkbox is cleared.'),
    s__('IDE|The %{boldStart}api%{boldEnd} scope is selected.'),
  ],
};

export default {
  name: 'WebIdeOAuthApplicationCallout',
  components: {
    GlAlert,
    GlSprintf,
    ResetApplicationSettingsModal,
  },
  props: {
    redirectUrlPath: {
      type: String,
      required: true,
    },
    resetApplicationSettingsPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isModalVisible: false,
    };
  },
  methods: {
    displayModal() {
      this.isModalVisible = true;
    },
    hideModal() {
      this.isModalVisible = false;
    },
    getRedirectUrl() {
      return new URL(this.redirectUrlPath, gon.gitlab_url);
    },
  },
  i18n: I18N_WEB_IDE_OAUTH_APPLICATION_CALLOUT,
};
</script>
<template>
  <div>
    <reset-application-settings-modal
      :visible="isModalVisible"
      :reset-application-settings-path="resetApplicationSettingsPath"
      @cancel="hideModal"
      @close="hideModal"
    />
    <gl-alert
      variant="info"
      class="gl-my-5"
      :dismissible="false"
      :primary-button-text="$options.i18n.alertButtonText"
      @primaryAction="displayModal"
    >
      <p>{{ $options.i18n.alertTitle }}</p>
      <ul class="gl-m-0">
        <li v-for="(message, index) in $options.i18n.configurations" :key="index">
          <gl-sprintf :message="message">
            <template #bold="{ content }">
              <strong>{{ content }}</strong>
            </template>
            <template #codeBlock="{ content }">
              <code>{{
                sprintf(content, {
                  pathFormat: redirectUrlPath,
                  example: `${getRedirectUrl()}`,
                })
              }}</code>
            </template>
          </gl-sprintf>
        </li>
      </ul>
    </gl-alert>
  </div>
</template>
