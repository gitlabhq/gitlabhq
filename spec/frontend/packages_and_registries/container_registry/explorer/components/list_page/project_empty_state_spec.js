import { GlFormInput, GlFormInputGroup, GlLink, GlSprintf } from '@gitlab/ui';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import projectEmptyState from '~/packages_and_registries/container_registry/explorer/components/list_page/project_empty_state.vue';
import { dockerCommands } from '../../mock_data';
import { GlEmptyState } from '../../stubs';

describe('Registry Project Empty state', () => {
  let wrapper;
  const config = {
    repositoryUrl: 'foo',
    registryHostUrlWithPort: 'bar',
    noContainersImage: 'bazFoo',
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(projectEmptyState, {
      stubs: {
        GlEmptyState,
        GlSprintf,
        GlFormInputGroup,
      },
      provide() {
        return {
          config,
          ...dockerCommands,
        };
      },
      ...props,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('basic structure', () => {
    it('renders empty state with correct props', () => {
      const emptyState = wrapper.findComponent(GlEmptyState);

      expect(emptyState.exists()).toBe(true);
      expect(emptyState.props('title')).toBe(
        'There are no container images stored for this project',
      );
      expect(emptyState.props('svgPath')).toBe(config.noContainersImage);
    });

    it('renders the intro text with documentation link', () => {
      const intro = wrapper.findByTestId('project-empty-state-intro');
      const docLink = intro.findComponent(GlLink);

      expect(intro.exists()).toBe(true);
      expect(docLink.exists()).toBe(true);
      expect(docLink.attributes('href')).toBe('/help/user/packages/container_registry/_index');
    });

    it('renders the quick start section', () => {
      expect(wrapper.find('h5').text()).toBe('CLI Commands');
    });
  });

  describe('authentication section', () => {
    it('renders the authentication message with correct links', () => {
      const authSection = wrapper.findByTestId('project-empty-state-authentication');
      const links = authSection.findAllComponents(GlLink);

      expect(links).toHaveLength(2);
      expect(links.at(0).attributes('href')).toBe(
        '/help/user/profile/account/two_factor_authentication',
      );
      expect(links.at(1).attributes('href')).toBe('/help/user/profile/personal_access_tokens');
    });
  });

  describe('docker commands', () => {
    let formGroups;

    beforeEach(() => {
      formGroups = wrapper.findAllComponents(GlFormInputGroup);
    });

    it('renders three command input groups', () => {
      expect(formGroups).toHaveLength(3);
    });

    describe('login command', () => {
      it('displays the correct docker login command', () => {
        const loginInput = formGroups.at(0).findComponent(GlFormInput);
        expect(loginInput.props('value')).toBe(dockerCommands.dockerLoginCommand);
      });

      it('has a working copy button', () => {
        const copyButton = formGroups.at(0).findComponent(ClipboardButton);
        expect(copyButton.exists()).toBe(true);
        expect(copyButton.props('text')).toBe(dockerCommands.dockerLoginCommand);
        expect(copyButton.props('title')).toBe('Copy login command');
      });
    });

    describe('build command', () => {
      it('displays the correct docker build command', () => {
        const buildInput = formGroups.at(1).findComponent(GlFormInput);
        expect(buildInput.props('value')).toBe(dockerCommands.dockerBuildCommand);
      });

      it('has a working copy button', () => {
        const copyButton = formGroups.at(1).findComponent(ClipboardButton);
        expect(copyButton.exists()).toBe(true);
        expect(copyButton.props('text')).toBe(dockerCommands.dockerBuildCommand);
        expect(copyButton.props('title')).toBe('Copy build command');
      });
    });

    describe('push command', () => {
      it('displays the correct docker push command', () => {
        const pushInput = formGroups.at(2).findComponent(GlFormInput);
        expect(pushInput.props('value')).toBe(dockerCommands.dockerPushCommand);
      });

      it('has a working copy button', () => {
        const copyButton = formGroups.at(2).findComponent(ClipboardButton);
        expect(copyButton.exists()).toBe(true);
        expect(copyButton.props('text')).toBe(dockerCommands.dockerPushCommand);
        expect(copyButton.props('title')).toBe('Copy push command');
      });
    });

    it('all input fields are readonly', () => {
      const inputs = wrapper.findAllComponents(GlFormInput);
      inputs.wrappers.forEach((input) => {
        expect(input.props('readonly')).toBe(true);
      });
    });
  });
});
