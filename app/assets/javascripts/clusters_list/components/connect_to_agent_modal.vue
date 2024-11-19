<script>
import { GlLink, GlModal, GlSprintf, GlButton } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__, __ } from '~/locale';
import { isGid, getIdFromGraphQLId } from '~/graphql_shared/utils';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';
import CodeBlockHighlighted from '~/vue_shared/components/code_block_highlighted.vue';
import { CONNECT_MODAL_ID } from '../constants';

export default {
  i18n: {
    title: s__('ClusterAgents|Connect to a cluster'),
    notConfiguredText: s__(
      'ClusterAgents|You can connect to your cluster from the command line. To use this feature, configure %{monotypeStart}user_access%{monotypeEnd} in the agent configuration project.',
    ),
    configuredText: s__(
      'ClusterAgents|You can connect to your cluster from the command line. Configure %{linkStart}kubectl%{linkEnd} command-line access by running the following command:',
    ),
    learMoreText: s__('ClusterAgents|Learn more about user access.'),
    buttonClose: __('Close'),
  },
  learnMoreDocsLink: helpPagePath('user/clusters/agent/user_access'),
  kubectlLink: 'https://kubernetes.io/docs/reference/kubectl/',
  modalId: CONNECT_MODAL_ID,
  components: {
    GlLink,
    GlModal,
    GlSprintf,
    GlButton,
    ModalCopyButton,
    CodeBlockHighlighted,
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    agentId: {
      type: String,
      required: true,
    },
    isConfigured: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      visible: false,
    };
  },
  computed: {
    descriptionText() {
      return this.isConfigured
        ? this.$options.i18n.configuredText
        : this.$options.i18n.notConfiguredText;
    },
    agentIdNumber() {
      return isGid(this.agentId) ? getIdFromGraphQLId(this.agentId) : this.agentId;
    },
    isRunningOnGitlabDotCom() {
      return gon?.dot_com;
    },
    currentHost() {
      return gon?.gitlab_url;
    },
    command() {
      if (this.isConfigured) {
        return this.glabCommand;
      }

      return `user_access:
  access_as:
      agent: {} # for free
      user: {} # for premium+
  projects:
      - id: <current project path>`;
    },
    glabCommand() {
      const baseCommand = `glab cluster agent update-kubeconfig --repo ${this.projectPath} --agent ${this.agentIdNumber} --use-context`;
      const hostVar = 'GITLAB_HOST';

      const hostPrefix = this.isRunningOnGitlabDotCom ? '' : `${hostVar}=${this.currentHost} `;

      return `${hostPrefix}${baseCommand}`;
    },
    commandLanguage() {
      return this.isConfigured ? 'shell' : 'yaml';
    },
  },
  methods: {
    hideModal() {
      this.visible = false;
    },
  },
};
</script>

<template>
  <gl-modal
    v-model="visible"
    :modal-id="$options.modalId"
    :title="$options.i18n.title"
    no-focus-on-show
  >
    <p>
      <gl-sprintf :message="descriptionText">
        <template #monotype="{ content }"
          ><code>{{ content }}</code>
        </template>

        <template #link="{ content }"
          ><gl-link
            :href="$options.kubectlLink"
            target="_blank"
            rel="noopener noreferrer nofollow"
            >{{ content }}</gl-link
          >
        </template>
      </gl-sprintf>
    </p>

    <p class="gl-flex gl-items-start">
      <code-block-highlighted
        :language="commandLanguage"
        class="gl-border gl-mb-0 gl-mr-3 gl-w-full gl-px-3 gl-py-2"
        :code="command"
      />
      <modal-copy-button :text="command" :modal-id="$options.modalId" category="tertiary" />
    </p>

    <p>
      <gl-link :href="$options.learnMoreDocsLink"> {{ $options.i18n.learMoreText }} </gl-link>
    </p>

    <template #modal-footer>
      <gl-button @click="hideModal">{{ $options.i18n.buttonClose }} </gl-button>
    </template>
  </gl-modal>
</template>
