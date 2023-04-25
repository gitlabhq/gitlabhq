import { GlAlert, GlModal, GlButton, GlSkeletonLoader } from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { shallowMount, ErrorWrapper } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import getRunnerPlatformsQuery from '~/vue_shared/components/runner_instructions/graphql/get_runner_platforms.query.graphql';
import RunnerInstructionsModal from '~/vue_shared/components/runner_instructions/runner_instructions_modal.vue';
import RunnerCliInstructions from '~/vue_shared/components/runner_instructions/instructions/runner_cli_instructions.vue';
import RunnerDockerInstructions from '~/vue_shared/components/runner_instructions/instructions/runner_docker_instructions.vue';
import RunnerKubernetesInstructions from '~/vue_shared/components/runner_instructions/instructions/runner_kubernetes_instructions.vue';
import RunnerAwsInstructions from '~/vue_shared/components/runner_instructions/instructions/runner_aws_instructions.vue';

import { mockRunnerPlatforms } from './mock_data';

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

  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findAlert = (variant = 'danger') => {
    const { wrappers } = wrapper
      .findAllComponents(GlAlert)
      .filter((w) => w.props('variant') === variant);
    return wrappers[0] || new ErrorWrapper();
  };
  const findModal = () => wrapper.findComponent(GlModal);
  const findPlatformButtonGroup = () => wrapper.findByTestId('platform-buttons');
  const findPlatformButtons = () => findPlatformButtonGroup().findAllComponents(GlButton);
  const findRunnerCliInstructions = () => wrapper.findComponent(RunnerCliInstructions);

  const createComponent = ({ props, shown = true, ...options } = {}) => {
    const requestHandlers = [[getRunnerPlatformsQuery, runnerPlatformsHandler]];

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
    runnerPlatformsHandler = jest.fn().mockResolvedValue(mockRunnerPlatforms);
  });

  describe('when the modal is shown', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('should not show alert', () => {
      expect(findAlert().exists()).toBe(false);
    });

    it('should not show deprecation alert', () => {
      expect(findAlert('warning').exists()).toBe(false);
    });

    it('should contain a number of platforms buttons', () => {
      expect(runnerPlatformsHandler).toHaveBeenCalledWith({});

      const buttons = findPlatformButtons();

      expect(buttons).toHaveLength(mockRunnerPlatforms.data.runnerPlatforms.nodes.length);
    });

    it('should display architecture options', () => {
      const { architectures } = findRunnerCliInstructions().props('platform');

      expect(architectures).toEqual(
        mockRunnerPlatforms.data.runnerPlatforms.nodes[0].architectures.nodes,
      );
    });

    describe.each`
      glFeatures                                    | deprecationAlertExists
      ${{}}                                         | ${false}
      ${{ createRunnerWorkflowForAdmin: true }}     | ${true}
      ${{ createRunnerWorkflowForNamespace: true }} | ${true}
    `('with features $glFeatures', ({ glFeatures, deprecationAlertExists }) => {
      beforeEach(() => {
        createComponent({ provide: { glFeatures } });
      });

      it(`alert is ${deprecationAlertExists ? 'shown' : 'not shown'}`, () => {
        expect(findAlert('warning').exists()).toBe(deprecationAlertExists);
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

  describe.each([null, 'DEFINED'])('when registration token is %p', (token) => {
    beforeEach(async () => {
      createComponent({ props: { registrationToken: token } });
      await waitForPromises();
    });

    it('register command is shown without a defined registration token', () => {
      expect(findRunnerCliInstructions().props('registrationToken')).toBe(token);
    });
  });

  describe('with a defaultPlatformName', () => {
    beforeEach(async () => {
      createComponent({ props: { defaultPlatformName: 'osx' } });
      await waitForPromises();
    });

    it('should preselect', () => {
      const selected = findPlatformButtons()
        .filter((btn) => btn.props('selected'))
        .at(0);

      expect(selected.text()).toBe('macOS');
    });

    it('runner instructions for the default selected platform are requested', () => {
      const { name } = findRunnerCliInstructions().props('platform');

      expect(name).toBe('osx');
    });
  });

  describe.each`
    platform        | component
    ${'docker'}     | ${RunnerDockerInstructions}
    ${'kubernetes'} | ${RunnerKubernetesInstructions}
    ${'aws'}        | ${RunnerAwsInstructions}
  `('with platform "$platform"', ({ platform, component }) => {
    beforeEach(async () => {
      createComponent({ props: { defaultPlatformName: platform } });
      await waitForPromises();
    });

    it(`runner instructions for ${platform} are shown`, () => {
      expect(wrapper.findComponent(component).exists()).toBe(true);
    });
  });

  describe('when the modal is not shown', () => {
    beforeEach(async () => {
      createComponent({ shown: false });
      await waitForPromises();
    });

    it('does not fetch instructions', () => {
      expect(runnerPlatformsHandler).not.toHaveBeenCalled();
    });
  });

  describe('when apollo is loading', () => {
    it('should show a skeleton loader', async () => {
      createComponent();
      await nextTick();

      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('once loaded, should not show a loading state', async () => {
      createComponent();
      await waitForPromises();

      expect(findSkeletonLoader().exists()).toBe(false);
    });
  });

  describe('errors', () => {
    it('should show an alert when platforms cannot be loaded', async () => {
      runnerPlatformsHandler.mockRejectedValue();

      createComponent();
      await waitForPromises();

      expect(findAlert().exists()).toBe(true);
    });

    it('should show an alert when instructions cannot be loaded', async () => {
      createComponent();
      await waitForPromises();

      findRunnerCliInstructions().vm.$emit('error');
      await waitForPromises();

      expect(findAlert().exists()).toBe(true);

      findAlert().vm.$emit('dismiss');
      await nextTick();

      expect(findAlert().exists()).toBe(false);
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
      let mockClose;

      beforeEach(() => {
        mockShow = jest.fn();
        mockClose = jest.fn();

        createComponent({
          shown: false,
          stubs: {
            GlModal: getGlModalStub({ show: mockShow, close: mockClose }),
          },
        });
      });

      it('delegates show()', () => {
        wrapper.vm.show();

        expect(mockShow).toHaveBeenCalledTimes(1);
      });

      it('delegates close()', () => {
        wrapper.vm.close();

        expect(mockClose).toHaveBeenCalledTimes(1);
      });
    });
  });
});
