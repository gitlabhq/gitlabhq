import { GlLink, GlModal, GlSprintf, GlButton } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import ConnectToAgentModal from '~/clusters_list/components/connect_to_agent_modal.vue';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';
import CodeBlockHighlighted from '~/vue_shared/components/code_block_highlighted.vue';
import { CONNECT_MODAL_ID } from '~/clusters_list/constants';
import { stubComponent } from 'helpers/stub_component';

const projectPath = 'path/to/project';
const agentId = '123';
const selfManagedHost = 'https://gitlab.example.com';

const modalDescriptionConfiguredAgent =
  'You can connect to your cluster from the command line. Configure kubectl command-line access by running the following command:';
const modalDescriptionNoConfiguredAgent =
  'You can connect to your cluster from the command line. To use this feature, configure user_access in the agent configuration project.';
const glabCommand =
  'glab cluster agent update-kubeconfig --repo path/to/project --agent 123 --use-context';
const glabCommandSelfManaged = `GITLAB_HOST=${selfManagedHost} ${glabCommand}`;
const yamlCommand = `user_access:
  access_as:
      agent: {} # for free
      user: {} # for premium+
  projects:
      - id: <current project path>`;

describe('ConnectToAgentModal', () => {
  let wrapper;

  const findModal = () => wrapper.findComponent(GlModal);
  const findModalCopyButton = () => wrapper.findComponent(ModalCopyButton);
  const findCodeBlock = () => wrapper.findComponent(CodeBlockHighlighted);
  const findDocsLink = () => wrapper.findComponent(GlLink);
  const findCloseButton = () => wrapper.findComponent(GlButton);

  const createWrapper = ({ isConfigured = false } = {}) => {
    const propsData = {
      projectPath,
      agentId,
      isConfigured,
    };

    wrapper = shallowMount(ConnectToAgentModal, {
      propsData,
      stubs: {
        GlSprintf,
        GlModal: stubComponent(GlModal, {
          template: '<div><slot></slot><slot name="modal-footer"></slot></div>',
        }),
      },
    });
  };

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders correct title for the modal', () => {
      expect(findModal().props('title')).toBe('Connect to a cluster');
    });

    it('renders link to the docs', () => {
      expect(findDocsLink().attributes('href')).toBe('/help/user/clusters/agent/user_access');
      expect(findDocsLink().text()).toBe('Learn more about user access.');
    });

    it('renders close button', () => {
      expect(findCloseButton().text()).toBe('Close');
    });

    it('hides the modal whe close button is clicked', async () => {
      findModal().vm.$emit('change', true);
      await nextTick();
      expect(findModal().props('visible')).toBe(true);

      findCloseButton().vm.$emit('click');
      await nextTick();

      expect(findModal().props('visible')).toBe(false);
    });
  });

  describe('when the agent is configured', () => {
    beforeEach(() => {
      gon.dot_com = true;
      createWrapper({ isConfigured: true });
    });

    it('renders correct description for the modal', () => {
      expect(findModal().text()).toContain(modalDescriptionConfiguredAgent);
    });

    it('renders code block with the correct command', () => {
      expect(findCodeBlock().props()).toMatchObject({
        language: 'shell',
        code: glabCommand,
      });
    });

    it('renders copy button with the correct props', () => {
      expect(findModalCopyButton().props()).toMatchObject({
        text: glabCommand,
        modalId: CONNECT_MODAL_ID,
      });
    });
  });

  describe('when the agent is configured on self-managed instance', () => {
    beforeEach(() => {
      gon.gitlab_url = selfManagedHost;
      gon.dot_com = false;
      createWrapper({ isConfigured: true });
    });

    it('renders correct description for the modal', () => {
      expect(findModal().text()).toContain(modalDescriptionConfiguredAgent);
    });

    it('renders code block with the correct language', () => {
      expect(findCodeBlock().props()).toMatchObject({
        language: 'shell',
        code: glabCommandSelfManaged,
      });
    });

    it('renders copy button with the correct props', () => {
      expect(findModalCopyButton().props()).toMatchObject({
        text: glabCommandSelfManaged,
        modalId: CONNECT_MODAL_ID,
      });
    });
  });

  describe('when the agent is not configured', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders correct description for the modal', () => {
      expect(findModal().text()).toContain(modalDescriptionNoConfiguredAgent);
    });

    it('renders code block with the correct command', () => {
      expect(findCodeBlock().props('language')).toBe('yaml');
      expect(findCodeBlock().props('code')).toBe(yamlCommand);
    });

    it('renders copy button with the correct props', () => {
      expect(findModalCopyButton().props()).toMatchObject({
        text: yamlCommand,
        modalId: CONNECT_MODAL_ID,
      });
    });
  });
});
