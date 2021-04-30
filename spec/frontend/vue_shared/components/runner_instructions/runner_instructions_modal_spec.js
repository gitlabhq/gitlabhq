import { GlAlert, GlButton, GlLoadingIcon, GlSkeletonLoader } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import getRunnerPlatformsQuery from '~/vue_shared/components/runner_instructions/graphql/queries/get_runner_platforms.query.graphql';
import getRunnerSetupInstructionsQuery from '~/vue_shared/components/runner_instructions/graphql/queries/get_runner_setup.query.graphql';
import RunnerInstructionsModal from '~/vue_shared/components/runner_instructions/runner_instructions_modal.vue';

import {
  mockGraphqlRunnerPlatforms,
  mockGraphqlInstructions,
  mockGraphqlInstructionsWindows,
} from './mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

let resizeCallback;
const MockResizeObserver = {
  bind(el, { value }) {
    resizeCallback = value;
  },
  mockResize(size) {
    bp.getBreakpointSize.mockReturnValue(size);
    resizeCallback();
  },
  unbind() {
    resizeCallback = null;
  },
};

localVue.directive('gl-resize-observer', MockResizeObserver);

jest.mock('@gitlab/ui/dist/utils');

describe('RunnerInstructionsModal component', () => {
  let wrapper;
  let fakeApollo;
  let runnerPlatformsHandler;
  let runnerSetupInstructionsHandler;

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findGlLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findPlatformButtonGroup = () => wrapper.findByTestId('platform-buttons');
  const findPlatformButtons = () => findPlatformButtonGroup().findAllComponents(GlButton);
  const findArchitectureDropdownItems = () => wrapper.findAllByTestId('architecture-dropdown-item');
  const findBinaryInstructions = () => wrapper.findByTestId('binary-instructions');
  const findRegisterCommand = () => wrapper.findByTestId('register-command');

  const createComponent = () => {
    const requestHandlers = [
      [getRunnerPlatformsQuery, runnerPlatformsHandler],
      [getRunnerSetupInstructionsQuery, runnerSetupInstructionsHandler],
    ];

    fakeApollo = createMockApollo(requestHandlers);

    wrapper = extendedWrapper(
      shallowMount(RunnerInstructionsModal, {
        propsData: {
          modalId: 'runner-instructions-modal',
        },
        localVue,
        apolloProvider: fakeApollo,
      }),
    );
  };

  beforeEach(async () => {
    runnerPlatformsHandler = jest.fn().mockResolvedValue(mockGraphqlRunnerPlatforms);
    runnerSetupInstructionsHandler = jest.fn().mockResolvedValue(mockGraphqlInstructions);

    createComponent();

    await nextTick();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should not show alert', () => {
    expect(findAlert().exists()).toBe(false);
  });

  it('should contain a number of platforms buttons', () => {
    expect(runnerPlatformsHandler).toHaveBeenCalledWith({});

    const buttons = findPlatformButtons();

    expect(buttons).toHaveLength(mockGraphqlRunnerPlatforms.data.runnerPlatforms.nodes.length);
  });

  it('should contain a number of dropdown items for the architecture options', () => {
    expect(findArchitectureDropdownItems()).toHaveLength(
      mockGraphqlRunnerPlatforms.data.runnerPlatforms.nodes[0].architectures.nodes.length,
    );
  });

  describe('should display default instructions', () => {
    const { installInstructions, registerInstructions } = mockGraphqlInstructions.data.runnerSetup;

    it('runner instructions are requested', () => {
      expect(runnerSetupInstructionsHandler).toHaveBeenCalledWith({
        platform: 'linux',
        architecture: 'amd64',
      });
    });

    it('binary instructions are shown', () => {
      const instructions = findBinaryInstructions().text();

      expect(instructions).toBe(installInstructions);
    });

    it('register command is shown', () => {
      const instructions = findRegisterCommand().text();

      expect(instructions).toBe(registerInstructions);
    });
  });

  describe('after a platform and architecture are selected', () => {
    const {
      installInstructions,
      registerInstructions,
    } = mockGraphqlInstructionsWindows.data.runnerSetup;

    beforeEach(async () => {
      runnerSetupInstructionsHandler.mockResolvedValue(mockGraphqlInstructionsWindows);

      findPlatformButtons().at(2).vm.$emit('click'); // another option, happens to be windows
      await nextTick();

      findArchitectureDropdownItems().at(1).vm.$emit('click'); // another option
      await nextTick();
    });

    it('runner instructions are requested', () => {
      expect(runnerSetupInstructionsHandler).toHaveBeenCalledWith({
        platform: 'windows',
        architecture: '386',
      });
    });

    it('other binary instructions are shown', () => {
      const instructions = findBinaryInstructions().text();

      expect(instructions).toBe(installInstructions);
    });

    it('register command is shown', () => {
      const command = findRegisterCommand().text();

      expect(command).toBe(registerInstructions);
    });
  });

  describe('when the modal resizes', () => {
    it('to an xs viewport', async () => {
      MockResizeObserver.mockResize('xs');
      await nextTick();

      expect(findPlatformButtonGroup().attributes('vertical')).toBeTruthy();
    });

    it('to a non-xs viewport', async () => {
      MockResizeObserver.mockResize('sm');
      await nextTick();

      expect(findPlatformButtonGroup().props('vertical')).toBeFalsy();
    });
  });

  describe('when apollo is loading', () => {
    it('should show a skeleton loader', async () => {
      createComponent();
      expect(findSkeletonLoader().exists()).toBe(true);
      expect(findGlLoadingIcon().exists()).toBe(false);

      await nextTick(); // wait for platforms

      expect(findGlLoadingIcon().exists()).toBe(true);
    });

    it('once loaded, should not show a loading state', async () => {
      createComponent();

      await nextTick(); // wait for platforms
      await nextTick(); // wait for architectures

      expect(findSkeletonLoader().exists()).toBe(false);
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
      expect(findAlert().exists()).toBe(true);
    });

    it('should not show instructions', () => {
      expect(findBinaryInstructions().exists()).toBe(false);
      expect(findRegisterCommand().exists()).toBe(false);
    });
  });
});
