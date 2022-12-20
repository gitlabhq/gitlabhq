import { GlAlert, GlModal, GlButton, GlLoadingIcon, GlSkeletonLoader } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
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

Vue.use(VueApollo);

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

Vue.directive('gl-resize-observer', MockResizeObserver);

jest.mock('@gitlab/ui/dist/utils');

describe('RunnerInstructionsModal component', () => {
  let wrapper;
  let fakeApollo;
  let runnerPlatformsHandler;
  let runnerSetupInstructionsHandler;

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findGlLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findModal = () => wrapper.findComponent(GlModal);
  const findPlatformButtonGroup = () => wrapper.findByTestId('platform-buttons');
  const findPlatformButtons = () => findPlatformButtonGroup().findAllComponents(GlButton);
  const findArchitectureDropdownItems = () => wrapper.findAllByTestId('architecture-dropdown-item');
  const findBinaryDownloadButton = () => wrapper.findByTestId('binary-download-button');
  const findBinaryInstructions = () => wrapper.findByTestId('binary-instructions');
  const findRegisterCommand = () => wrapper.findByTestId('register-command');

  const createComponent = ({ props, shown = true, ...options } = {}) => {
    const requestHandlers = [
      [getRunnerPlatformsQuery, runnerPlatformsHandler],
      [getRunnerSetupInstructionsQuery, runnerSetupInstructionsHandler],
    ];

    fakeApollo = createMockApollo(requestHandlers);

    wrapper = extendedWrapper(
      shallowMount(RunnerInstructionsModal, {
        propsData: {
          modalId: 'runner-instructions-modal',
          registrationToken: 'MY_TOKEN',
          ...props,
        },
        apolloProvider: fakeApollo,
        ...options,
      }),
    );

    // trigger open modal
    if (shown) {
      findModal().vm.$emit('shown');
    }
  };

  beforeEach(() => {
    runnerPlatformsHandler = jest.fn().mockResolvedValue(mockGraphqlRunnerPlatforms);
    runnerSetupInstructionsHandler = jest.fn().mockResolvedValue(mockGraphqlInstructions);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when the modal is shown', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('should not show alert', async () => {
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
      const { installInstructions } = mockGraphqlInstructions.data.runnerSetup;

      it('runner instructions are requested', () => {
        expect(runnerSetupInstructionsHandler).toHaveBeenCalledWith({
          platform: 'linux',
          architecture: 'amd64',
        });
      });

      it('binary instructions are shown', async () => {
        const instructions = findBinaryInstructions().text();

        expect(instructions).toBe(installInstructions.trim());
      });

      it('register command is shown with a replaced token', async () => {
        const command = findRegisterCommand().text();

        expect(command).toBe(
          'sudo gitlab-runner register --url http://localhost/ --registration-token MY_TOKEN',
        );
      });
    });

    describe('after a platform and architecture are selected', () => {
      const windowsIndex = 2;
      const { installInstructions } = mockGraphqlInstructionsWindows.data.runnerSetup;

      beforeEach(async () => {
        runnerSetupInstructionsHandler.mockResolvedValue(mockGraphqlInstructionsWindows);

        findPlatformButtons().at(windowsIndex).vm.$emit('click');
        await waitForPromises();
      });

      it('runner instructions are requested', () => {
        expect(runnerSetupInstructionsHandler).toHaveBeenLastCalledWith({
          platform: 'windows',
          architecture: 'amd64',
        });
      });

      it('architecture download link is updated', () => {
        const architectures =
          mockGraphqlRunnerPlatforms.data.runnerPlatforms.nodes[windowsIndex].architectures.nodes;

        expect(findBinaryDownloadButton().attributes('href')).toBe(
          architectures[0].downloadLocation,
        );
      });

      it('other binary instructions are shown', () => {
        const instructions = findBinaryInstructions().text();

        expect(instructions).toBe(installInstructions.trim());
      });

      it('register command is shown', () => {
        const command = findRegisterCommand().text();

        expect(command).toBe(
          './gitlab-runner.exe register --url http://localhost/ --registration-token MY_TOKEN',
        );
      });

      it('runner instructions are requested with another architecture', async () => {
        findArchitectureDropdownItems().at(1).vm.$emit('click');
        await waitForPromises();

        expect(runnerSetupInstructionsHandler).toHaveBeenLastCalledWith({
          platform: 'windows',
          architecture: '386',
        });
      });
    });

    describe('when the modal resizes', () => {
      it('to an xs viewport', async () => {
        MockResizeObserver.mockResize('xs');
        await nextTick();

        expect(findPlatformButtonGroup().attributes('vertical')).toEqual('true');
      });

      it('to a non-xs viewport', async () => {
        MockResizeObserver.mockResize('sm');
        await nextTick();

        expect(findPlatformButtonGroup().props('vertical')).toBeUndefined();
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

      expect(instructions).toBe(mockGraphqlInstructions.data.runnerSetup.registerInstructions);
    });
  });

  describe('with a defaultPlatformName', () => {
    beforeEach(async () => {
      createComponent({ props: { defaultPlatformName: 'osx' } });
      await waitForPromises();
    });

    it('runner instructions for the default selected platform are requested', () => {
      expect(runnerSetupInstructionsHandler).toHaveBeenLastCalledWith({
        platform: 'osx',
        architecture: 'amd64',
      });
    });

    it('sets the focus on the default selected platform', () => {
      const findOsxPlatformButton = () => wrapper.findComponent({ ref: 'osx' });

      findOsxPlatformButton().element.focus = jest.fn();

      findModal().vm.$emit('shown');

      expect(findOsxPlatformButton().element.focus).toHaveBeenCalled();
    });
  });

  describe('when the modal is not shown', () => {
    beforeEach(async () => {
      createComponent({ shown: false });
      await waitForPromises();
    });

    it('does not fetch instructions', () => {
      expect(runnerPlatformsHandler).not.toHaveBeenCalled();
      expect(runnerSetupInstructionsHandler).not.toHaveBeenCalled();
    });
  });

  describe('when apollo is loading', () => {
    it('should show a skeleton loader', async () => {
      createComponent();
      await nextTick();
      await nextTick();

      expect(findSkeletonLoader().exists()).toBe(true);
      expect(findGlLoadingIcon().exists()).toBe(false);

      // wait on fetch of both `platforms` and `instructions`
      await nextTick();
      await nextTick();

      expect(findGlLoadingIcon().exists()).toBe(true);
    });

    it('once loaded, should not show a loading state', async () => {
      createComponent();

      await waitForPromises();

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

  describe('GlModal API', () => {
    const getGlModalStub = (methods) => {
      return {
        ...GlModal,
        methods: {
          ...GlModal.methods,
          ...methods,
        },
      };
    };

    describe('show()', () => {
      let mockShow;

      beforeEach(() => {
        mockShow = jest.fn();

        createComponent({
          shown: false,
          stubs: {
            GlModal: getGlModalStub({ show: mockShow }),
          },
        });
      });

      it('delegates show()', () => {
        wrapper.vm.show();

        expect(mockShow).toHaveBeenCalledTimes(1);
      });
    });
  });
});
