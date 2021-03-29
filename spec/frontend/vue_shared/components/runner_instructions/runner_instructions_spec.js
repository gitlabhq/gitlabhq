import { GlAlert } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import getRunnerPlatforms from '~/vue_shared/components/runner_instructions/graphql/queries/get_runner_platforms.query.graphql';
import getRunnerSetupInstructions from '~/vue_shared/components/runner_instructions/graphql/queries/get_runner_setup.query.graphql';
import RunnerInstructions from '~/vue_shared/components/runner_instructions/runner_instructions.vue';

import { mockGraphqlRunnerPlatforms, mockGraphqlInstructions } from './mock_data';

const projectPath = 'gitlab-org/gitlab';
const localVue = createLocalVue();
localVue.use(VueApollo);

describe('RunnerInstructions component', () => {
  let wrapper;
  let fakeApollo;
  let runnerPlatformsHandler;
  let runnerSetupInstructionsHandler;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findModalButton = () => wrapper.find('[data-testid="show-modal-button"]');
  const findPlatformButtons = () => wrapper.findAll('[data-testid="platform-button"]');
  const findArchitectureDropdownItems = () =>
    wrapper.findAll('[data-testid="architecture-dropdown-item"]');
  const findBinaryInstructionsSection = () => wrapper.find('[data-testid="binary-instructions"]');
  const findRunnerInstructionsSection = () => wrapper.find('[data-testid="runner-instructions"]');

  const createComponent = () => {
    const requestHandlers = [
      [getRunnerPlatforms, runnerPlatformsHandler],
      [getRunnerSetupInstructions, runnerSetupInstructionsHandler],
    ];

    fakeApollo = createMockApollo(requestHandlers);

    wrapper = shallowMount(RunnerInstructions, {
      provide: {
        projectPath,
      },
      localVue,
      apolloProvider: fakeApollo,
    });
  };

  beforeEach(async () => {
    runnerPlatformsHandler = jest.fn().mockResolvedValue(mockGraphqlRunnerPlatforms);
    runnerSetupInstructionsHandler = jest.fn().mockResolvedValue(mockGraphqlInstructions);

    createComponent();

    await wrapper.vm.$nextTick();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('should not show alert', () => {
    expect(findAlert().exists()).toBe(false);
  });

  it('should show the "Show Runner installation instructions" button', () => {
    const button = findModalButton();

    expect(button.exists()).toBe(true);
    expect(button.text()).toBe('Show Runner installation instructions');
  });

  it('should contain a number of platforms buttons', () => {
    const buttons = findPlatformButtons();

    expect(buttons).toHaveLength(mockGraphqlRunnerPlatforms.data.runnerPlatforms.nodes.length);
  });

  it('should contain a number of dropdown items for the architecture options', () => {
    const platformButton = findPlatformButtons().at(0);
    platformButton.vm.$emit('click');

    return wrapper.vm.$nextTick(() => {
      const dropdownItems = findArchitectureDropdownItems();

      expect(dropdownItems).toHaveLength(
        mockGraphqlRunnerPlatforms.data.runnerPlatforms.nodes[0].architectures.nodes.length,
      );
    });
  });

  it('should display the binary installation instructions for a selected architecture', async () => {
    const platformButton = findPlatformButtons().at(0);
    platformButton.vm.$emit('click');

    await wrapper.vm.$nextTick();

    const dropdownItem = findArchitectureDropdownItems().at(0);
    dropdownItem.vm.$emit('click');

    await wrapper.vm.$nextTick();

    const runner = findBinaryInstructionsSection();

    expect(runner.text()).toMatch('sudo chmod +x /usr/local/bin/gitlab-runner');
    expect(runner.text()).toMatch(
      `sudo useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash`,
    );
    expect(runner.text()).toMatch(
      'sudo gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner',
    );
    expect(runner.text()).toMatch('sudo gitlab-runner start');
  });

  it('should display the runner register instructions for a selected architecture', async () => {
    const platformButton = findPlatformButtons().at(0);
    platformButton.vm.$emit('click');

    await wrapper.vm.$nextTick();

    const dropdownItem = findArchitectureDropdownItems().at(0);
    dropdownItem.vm.$emit('click');

    await wrapper.vm.$nextTick();

    const runner = findRunnerInstructionsSection();

    expect(runner.text()).toMatch(mockGraphqlInstructions.data.runnerSetup.registerInstructions);
  });

  describe('when instructions cannot be loaded', () => {
    beforeEach(async () => {
      runnerSetupInstructionsHandler.mockRejectedValue();

      createComponent();

      await wrapper.vm.$nextTick();
    });

    it('should show alert', () => {
      expect(findAlert().exists()).toBe(true);
    });

    it('should not show instructions', () => {
      expect(findBinaryInstructionsSection().exists()).toBe(false);
      expect(findRunnerInstructionsSection().exists()).toBe(false);
    });
  });
});
