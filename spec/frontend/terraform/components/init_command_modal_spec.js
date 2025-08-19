import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import InitCommandModal from '~/terraform/components/init_command_modal.vue';

const accessTokensPath = '/path/to/access-tokens-page';
const terraformApiUrl = 'https://gitlab.com/api/v4/projects/1';
const username = 'username';
const projectPath = 'group/project';
const modalId = 'fake-modal-id';
const stateName = 'aws/eu-central-1';
const stateNameEncoded = encodeURIComponent(stateName);
const modalInfoCopyStrPlain = `export GITLAB_ACCESS_TOKEN=<YOUR-ACCESS-TOKEN>
export TF_STATE_NAME=${stateNameEncoded}
terraform init \\
    -backend-config="address=${terraformApiUrl}/$TF_STATE_NAME" \\
    -backend-config="lock_address=${terraformApiUrl}/$TF_STATE_NAME/lock" \\
    -backend-config="unlock_address=${terraformApiUrl}/$TF_STATE_NAME/lock" \\
    -backend-config="username=${username}" \\
    -backend-config="password=$GITLAB_ACCESS_TOKEN" \\
    -backend-config="lock_method=POST" \\
    -backend-config="unlock_method=DELETE" \\
    -backend-config="retry_wait_min=5"
    `;
const modalInfoCopyStrGlab = `glab opentofu init -R '${projectPath}' '${stateName}'`;

describe('InitCommandModal', () => {
  let wrapper;

  const propsData = {
    modalId,
    stateName,
  };
  const provideData = {
    accessTokensPath,
    terraformApiUrl,
    username,
    projectPath,
  };

  const mountComponent = ({ props = propsData } = {}) => {
    wrapper = shallowMountExtended(InitCommandModal, {
      propsData: props,
      provide: provideData,
      stubs: {
        GlSprintf,
      },
    });
  };

  const findExplanatoryGlabText = () => wrapper.findByTestId('init-command-explanatory-glab-text');
  const findExplanatoryPlainText = () =>
    wrapper.findByTestId('init-command-explanatory-plain-text');
  const findLink = () => wrapper.findComponent(GlLink);
  const findInitCommand = () => wrapper.findByTestId('terraform-init-command');
  const findGlabCommand = () => wrapper.findByTestId('glab-command');
  const findPlainCopyButton = () => wrapper.findByTestId('terraform-init-command-copy-button');
  const findGlabCopyButton = () => wrapper.findByTestId('glab-command-copy-button');

  describe('when has stateName', () => {
    beforeEach(() => {
      mountComponent();
    });

    describe('on rendering', () => {
      it('renders the explanatory plain text', () => {
        expect(findExplanatoryPlainText().text()).toContain('personal access token');
      });

      it('renders the explanatory glab text', () => {
        expect(findExplanatoryGlabText().text()).toContain('Run the following command with glab');
      });

      it('renders the personal access token link', () => {
        expect(findLink().attributes('href')).toBe(accessTokensPath);
      });

      describe('init command', () => {
        it('includes correct address', () => {
          expect(findInitCommand().text()).toContain(
            `-backend-config="address=${terraformApiUrl}/$TF_STATE_NAME"`,
          );
        });

        it('includes correct username', () => {
          expect(findInitCommand().text()).toContain(`-backend-config="username=${username}"`);
        });

        it('correct glab command', () => {
          expect(findGlabCommand().text()).toContain(
            `glab opentofu init -R '${projectPath}' '${stateName}'`,
          );
        });
      });

      it('renders the terraform init command copyToClipboard button', () => {
        expect(findPlainCopyButton().exists()).toBe(true);
      });

      it('renders the glab command copyToClipboard button', () => {
        expect(findGlabCopyButton().exists()).toBe(true);
      });
    });

    describe('when copy button is clicked', () => {
      it('copies terraform init command to clipboard', () => {
        expect(findPlainCopyButton().props('text')).toBe(modalInfoCopyStrPlain);
      });

      it('copies glab command to clipboard', () => {
        expect(findGlabCopyButton().props('text')).toBe(modalInfoCopyStrGlab);
      });
    });
  });
  describe('when has no stateName', () => {
    beforeEach(() => {
      mountComponent({ props: { modalId } });
    });

    describe('on rendering', () => {
      it('includes correct address', () => {
        expect(findInitCommand().text()).toContain(
          `-backend-config="address=${terraformApiUrl}/$TF_STATE_NAME"`,
        );
      });
    });
  });
});
