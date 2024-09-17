import { GlAlert, GlFormInputGroup, GlSprintf, GlLink, GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { sprintf } from '~/locale';
import AgentToken from '~/clusters_list/components/agent_token.vue';
import {
  I18N_AGENT_TOKEN,
  INSTALL_AGENT_MODAL_ID,
  NAME_MAX_LENGTH,
  HELM_VERSION_POLICY_URL,
} from '~/clusters_list/constants';
import { generateAgentRegistrationCommand } from '~/clusters_list/clusters_util';
import CodeBlock from '~/vue_shared/components/code_block.vue';

const kasAddress = 'kas.example.com';
const agentName = 'my-agent';
const agentToken = 'agent-token';
const kasInstallVersion = '15.0.0';
const modalId = INSTALL_AGENT_MODAL_ID;

describe('InstallAgentModal', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findCodeBlock = () => wrapper.findComponent(CodeBlock);
  const findCopyButton = () => wrapper.findComponentByTestId('agent-registration-command');
  const findInput = () => wrapper.findComponent(GlFormInputGroup);
  const findHelmVersionPolicyLink = () => wrapper.findComponent(GlLink);
  const findHelmExternalLinkIcon = () => wrapper.findComponent(GlIcon);

  const createWrapper = (newAgentName = agentName) => {
    const provide = {
      kasAddress,
      kasInstallVersion,
    };

    const propsData = {
      agentName: newAgentName,
      agentToken,
      modalId,
    };

    wrapper = shallowMountExtended(AgentToken, {
      provide,
      propsData,
      stubs: {
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    createWrapper();
  });

  describe('initial state', () => {
    it('shows basic agent installation instructions', () => {
      expect(wrapper.text()).toContain(I18N_AGENT_TOKEN.basicInstallTitle);
      expect(wrapper.text()).toContain(I18N_AGENT_TOKEN.basicInstallBody);
    });

    it('shows Helm version policy text with an external link', () => {
      expect(wrapper.text()).toContain(
        sprintf(I18N_AGENT_TOKEN.helmVersionText, { linkStart: '', linkEnd: ' ' }),
      );
      expect(findHelmVersionPolicyLink().attributes()).toMatchObject({
        href: HELM_VERSION_POLICY_URL,
        target: '_blank',
      });
      expect(findHelmExternalLinkIcon().props()).toMatchObject({ name: 'external-link', size: 12 });
    });

    it('shows advanced agent installation instructions', () => {
      expect(wrapper.text()).toContain(I18N_AGENT_TOKEN.advancedInstallTitle);
    });

    it('shows agent token as an input value', () => {
      expect(findInput().props('value')).toBe(agentToken);
    });

    it('renders a copy button', () => {
      expect(findCopyButton().props()).toMatchObject({
        title: 'Copy command',
        text: generateAgentRegistrationCommand({
          name: agentName,
          token: agentToken,
          version: kasInstallVersion,
          address: kasAddress,
        }),
        modalId,
      });
    });

    it('shows warning alert', () => {
      expect(findAlert().text()).toBe(I18N_AGENT_TOKEN.tokenSingleUseWarningTitle);
    });

    describe('when on dot_com', () => {
      beforeEach(() => {
        gon.dot_com = true;

        createWrapper();
      });

      it('shows code block with agent installation command without image version', () => {
        expect(findCodeBlock().props('code')).toContain(`helm upgrade --install ${agentName}`);
        expect(findCodeBlock().props('code')).toContain(`--namespace gitlab-agent-${agentName}`);
        expect(findCodeBlock().props('code')).toContain(`--set config.token=${agentToken}`);
        expect(findCodeBlock().props('code')).toContain(`--set config.kasAddress=${kasAddress}`);
        expect(findCodeBlock().props('code')).not.toContain(
          `--set image.tag=v${kasInstallVersion}`,
        );
      });
    });

    describe('when not on dot_com', () => {
      beforeEach(() => {
        gon.dot_com = false;

        createWrapper();
      });

      it('shows code block with agent installation command with image version', () => {
        expect(findCodeBlock().props('code')).toContain(`helm upgrade --install ${agentName}`);
        expect(findCodeBlock().props('code')).toContain(`--namespace gitlab-agent-${agentName}`);
        expect(findCodeBlock().props('code')).toContain(`--set config.token=${agentToken}`);
        expect(findCodeBlock().props('code')).toContain(`--set config.kasAddress=${kasAddress}`);
        expect(findCodeBlock().props('code')).toContain(`--set image.tag=v${kasInstallVersion}`);
      });
    });

    it('truncates the namespace name if it exceeds the maximum length', () => {
      const newAgentName = 'agent-name-that-is-too-long-and-needs-to-be-truncated-to-use';
      createWrapper(newAgentName);

      expect(findCodeBlock().props('code')).toContain(
        `--namespace gitlab-agent-${newAgentName.substring(0, NAME_MAX_LENGTH)}`,
      );
    });
  });
});
