import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import GitopsDeprecationAlert from '~/clusters_list/components/gitops_deprecation_alert.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import Api from '~/api';
import { HTTP_STATUS_NO_CONTENT, HTTP_STATUS_NOT_FOUND } from '~/lib/utils/http_status';

const projectGid = 'gid://gitlab/Project/1';
const installDocsUrl = helpPagePath('user/clusters/agent/gitops/migrate_to_flux');
const agentConfigPath = '.gitlab/agents/my-agent';

const rawFileWithGitops = `gitops:
  manifest_projects:
  - id: my-project`;
const rawFileWithoutGitops = `ci_access:
  manifest_projects:
  - id: my-project`;

describe('GitopsDeprecationAlert', () => {
  let wrapper;

  const createWrapper = (props) => {
    wrapper = shallowMount(GitopsDeprecationAlert, {
      propsData: {
        projectGid,
        agentConfigs: [agentConfigPath],
        ...props,
      },
      stubs: { GlSprintf },
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findDocsLink = () => wrapper.findComponent(GlLink);

  describe('on mount', () => {
    beforeEach(() => {
      jest.spyOn(Api, 'getRawFile').mockReturnValue(Promise.resolve({ data: '' }));
      createWrapper();
    });

    it('requests the config file from the API', () => {
      expect(Api.getRawFile).toHaveBeenCalledWith(1, `${agentConfigPath}/config.yaml`);
    });
  });

  describe('when no gitops config is present', () => {
    beforeEach(() => {
      jest
        .spyOn(Api, 'getRawFile')
        .mockReturnValue(Promise.resolve({ data: rawFileWithoutGitops }));
      createWrapper();
    });

    it('does not render an alert', () => {
      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('when one gitops config is present', () => {
    beforeEach(() => {
      jest.spyOn(Api, 'getRawFile').mockReturnValue(Promise.resolve({ data: rawFileWithGitops }));
      createWrapper();
    });

    it('renders an alert with the deprecation message', () => {
      expect(findAlert().text()).toBe(
        'The pull-based deployment features of the GitLab agent for Kubernetes is deprecated. If you use the agent for pull-based deployments, you should migrate to Flux.',
      );
    });

    it('renders a link to the documentation', () => {
      expect(findDocsLink().attributes('href')).toBe(installDocsUrl);
    });
  });

  describe('when multiple config path are present', () => {
    beforeEach(() => {
      jest
        .spyOn(Api, 'getRawFile')
        .mockReturnValueOnce(Promise.resolve({ data: rawFileWithoutGitops }))
        .mockReturnValueOnce(Promise.resolve({ data: rawFileWithGitops }));
      createWrapper({
        agentConfigs: [
          '.gitlab/agents/my-agent-1',
          '.gitlab/agents/my-agent-2',
          '.gitlab/agents/my-agent-3',
          '.gitlab/agents/my-agent-4',
        ],
      });
    });

    it('requests the config files from the API till the first gitops keyword is found', () => {
      expect(Api.getRawFile).toHaveBeenCalledTimes(2);

      expect(Api.getRawFile).toHaveBeenCalledWith(1, '.gitlab/agents/my-agent-1/config.yaml');
      expect(Api.getRawFile).toHaveBeenCalledWith(1, '.gitlab/agents/my-agent-2/config.yaml');
      expect(Api.getRawFile).not.toHaveBeenCalledWith(1, '.gitlab/agents/my-agent-3/config.yaml');
      expect(Api.getRawFile).not.toHaveBeenCalledWith(1, '.gitlab/agents/my-agent-4/config.yaml');
    });
  });

  describe('when one of the API calls fails', () => {
    beforeEach(() => {
      jest
        .spyOn(Api, 'getRawFile')
        .mockReturnValueOnce(Promise.resolve({ response: HTTP_STATUS_NOT_FOUND }))
        .mockReturnValueOnce(Promise.resolve({ data: rawFileWithGitops }));
      createWrapper({
        agentConfigs: ['.gitlab/agents/my-agent-1', '.gitlab/agents/my-agent-2'],
      });
    });

    it('requests the next config file', () => {
      expect(Api.getRawFile).toHaveBeenCalledTimes(2);

      expect(Api.getRawFile).toHaveBeenCalledWith(1, '.gitlab/agents/my-agent-1/config.yaml');
      expect(Api.getRawFile).toHaveBeenCalledWith(1, '.gitlab/agents/my-agent-2/config.yaml');
    });
  });

  describe('when all API calls fail', () => {
    beforeEach(() => {
      jest
        .spyOn(Api, 'getRawFile')
        .mockReturnValueOnce(Promise.resolve({ response: HTTP_STATUS_NOT_FOUND }))
        .mockReturnValueOnce(Promise.resolve({ response: HTTP_STATUS_NO_CONTENT }));
      createWrapper({
        agentConfigs: ['.gitlab/agents/my-agent-1', '.gitlab/agents/my-agent-2'],
      });
    });

    it('does not render an alert', () => {
      expect(findAlert().exists()).toBe(false);
    });
  });
});
