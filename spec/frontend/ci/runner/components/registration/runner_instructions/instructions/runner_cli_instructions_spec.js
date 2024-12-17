import { GlAlert, GlListboxItem, GlLoadingIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import getRunnerSetupInstructionsQuery from '~/ci/runner/components/registration/runner_instructions/graphql/get_runner_setup.query.graphql';
import RunnerCliInstructions from '~/ci/runner/components/registration/runner_instructions/instructions/runner_cli_instructions.vue';

import { mockRunnerPlatforms, mockInstructions, mockInstructionsWindows } from '../mock_data';

Vue.use(VueApollo);

jest.mock('@gitlab/ui/dist/utils');

const mockPlatforms = mockRunnerPlatforms.data.runnerPlatforms.nodes.map(
  ({ name, humanReadableName, architectures }) => ({
    name,
    humanReadableName,
    architectures: architectures?.nodes || [],
  }),
);

const [mockPlatform, mockPlatform2] = mockPlatforms;
const mockArchitectures = mockPlatform.architectures;

describe('RunnerCliInstructions component', () => {
  let wrapper;
  let fakeApollo;
  let runnerSetupInstructionsHandler;

  const findGlLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findArchitectureDropdownItems = () => wrapper.findAllComponents(GlListboxItem);
  const findBinaryDownloadButton = () => wrapper.findByTestId('binary-download-button');
  const findBinaryInstructions = () => wrapper.findByTestId('binary-instructions');
  const findRegisterCommand = () => wrapper.findByTestId('register-command');

  const createComponent = ({ props, ...options } = {}) => {
    const requestHandlers = [[getRunnerSetupInstructionsQuery, runnerSetupInstructionsHandler]];

    fakeApollo = createMockApollo(requestHandlers);

    wrapper = extendedWrapper(
      mount(RunnerCliInstructions, {
        propsData: {
          platform: mockPlatform,
          registrationToken: 'MY_TOKEN',
          ...props,
        },
        apolloProvider: fakeApollo,
        ...options,
      }),
    );
  };

  beforeEach(() => {
    runnerSetupInstructionsHandler = jest.fn().mockResolvedValue(mockInstructions);
  });

  describe('when the instructions are shown', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('should not show alert', () => {
      expect(findAlert().exists()).toBe(false);
    });

    it('should contain a number of dropdown items for the architecture options', () => {
      expect(findArchitectureDropdownItems()).toHaveLength(
        mockRunnerPlatforms.data.runnerPlatforms.nodes[0].architectures.nodes.length,
      );
    });

    describe('should display instructions', () => {
      const { installInstructions } = mockInstructions.data.runnerSetup;

      it('runner instructions are requested', () => {
        expect(runnerSetupInstructionsHandler).toHaveBeenCalledWith({
          platform: 'linux',
          architecture: 'amd64',
        });
      });

      it('binary instructions are shown', () => {
        const instructions = findBinaryInstructions().text();

        expect(instructions).toBe(installInstructions.trim());
      });

      it('register command is shown with a replaced token', () => {
        const command = findRegisterCommand().text();

        expect(command).toBe(
          'sudo gitlab-runner register --url http://localhost/ --registration-token MY_TOKEN',
        );
      });

      it('architecture download link is shown', () => {
        expect(findBinaryDownloadButton().attributes('href')).toBe(
          mockArchitectures[0].downloadLocation,
        );
      });
    });

    describe('after another platform and architecture are selected', () => {
      beforeEach(async () => {
        runnerSetupInstructionsHandler.mockResolvedValue(mockInstructionsWindows);

        findArchitectureDropdownItems().at(1).vm.$emit('click');

        wrapper.setProps({ platform: mockPlatform2 });
        await waitForPromises();
      });

      it('runner instructions are requested', () => {
        expect(runnerSetupInstructionsHandler).toHaveBeenLastCalledWith({
          platform: mockPlatform2.name,
          architecture: mockPlatform2.architectures[0].name,
        });
      });
    });
  });

  describe('when a register token is not known', () => {
    beforeEach(async () => {
      createComponent({ props: { registrationToken: undefined } });
      await waitForPromises();
    });

    it('register command is shown without a defined registration token', () => {
      const instructions = findRegisterCommand().text();

      expect(instructions).toBe(mockInstructions.data.runnerSetup.registerInstructions);
    });
  });

  describe('when apollo is loading', () => {
    it('should show a loading icon', async () => {
      createComponent();

      expect(findGlLoadingIcon().exists()).toBe(true);

      await waitForPromises();

      expect(findGlLoadingIcon().exists()).toBe(false);
    });
  });

  describe('when instructions cannot be loaded', () => {
    beforeEach(async () => {
      runnerSetupInstructionsHandler.mockRejectedValue();

      createComponent();
      await waitForPromises();
    });

    it('should show alert', () => {
      expect(wrapper.emitted()).toEqual({ error: [[]] });
    });
  });
});
