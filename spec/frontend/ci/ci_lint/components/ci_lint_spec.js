import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import mockCiLintMutationResponse from 'test_fixtures/graphql/ci/pipeline_editor/graphql/mutations/ci_lint.mutation.graphql.json';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import CiLint from '~/ci/ci_lint/components/ci_lint.vue';
import CiLintResults from '~/ci/pipeline_editor/components/lint/ci_lint_results.vue';
import ciLintMutation from '~/ci/pipeline_editor/graphql/mutations/ci_lint.mutation.graphql';
import SourceEditor from '~/vue_shared/components/source_editor.vue';

Vue.use(VueApollo);

describe('CI Lint', () => {
  let wrapper;
  let mockCiLintData;

  const content =
    "test_job:\n  stage: build\n  script: echo 'Building'\n  only:\n    - web\n    - chat\n    - pushes\n  allow_failure: true  ";

  const createComponent = () => {
    const handlers = [[ciLintMutation, mockCiLintData]];
    const mockApollo = createMockApollo(handlers);

    wrapper = shallowMount(CiLint, {
      data() {
        return {
          content,
        };
      },
      propsData: {
        pipelineSimulationHelpPagePath: '/help/ci/lint#pipeline-simulation',
        lintHelpPagePath: '/help/ci/lint#anchor',
        projectFullPath: '/path/to/project',
      },
      apolloProvider: mockApollo,
    });
  };

  const findEditor = () => wrapper.findComponent(SourceEditor);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findCiLintResults = () => wrapper.findComponent(CiLintResults);
  const findValidateBtn = () => wrapper.find('[data-testid="ci-lint-validate"]');
  const findClearBtn = () => wrapper.find('[data-testid="ci-lint-clear"]');
  const findDryRunToggle = () => wrapper.find('[data-testid="ci-lint-dryrun"]');

  beforeEach(() => {
    mockCiLintData = jest.fn();
  });

  it('displays the editor', () => {
    createComponent();
    expect(findEditor().exists()).toBe(true);
  });

  it('validate action calls mutation correctly', () => {
    createComponent();
    findValidateBtn().vm.$emit('click');

    expect(mockCiLintData).toHaveBeenCalledWith({
      projectPath: '/path/to/project',
      content,
      dryRun: false,
    });
  });

  it('validate action calls mutation with dry run', () => {
    createComponent();
    findDryRunToggle().vm.$emit('input', true);
    findValidateBtn().vm.$emit('click');

    expect(mockCiLintData).toHaveBeenCalledWith({
      projectPath: '/path/to/project',
      content,
      dryRun: true,
    });
  });

  it('validation displays results', async () => {
    mockCiLintData.mockResolvedValue(mockCiLintMutationResponse);
    createComponent();
    findValidateBtn().vm.$emit('click');

    await nextTick();

    expect(findValidateBtn().props('loading')).toBe(true);

    await waitForPromises();

    expect(findCiLintResults().exists()).toBe(true);
    expect(findValidateBtn().props('loading')).toBe(false);
  });

  it('validation displays error', async () => {
    mockCiLintData.mockRejectedValueOnce(new Error('Error!'));
    createComponent();

    findValidateBtn().vm.$emit('click');

    await nextTick();

    expect(findValidateBtn().props('loading')).toBe(true);

    await waitForPromises();

    expect(findCiLintResults().exists()).toBe(false);
    expect(findAlert().text()).toBe('Error: Error!');
    expect(findValidateBtn().props('loading')).toBe(false);
  });

  it('content is cleared on clear action', async () => {
    createComponent();
    expect(findEditor().props('value')).toBe(content);

    await findClearBtn().vm.$emit('click');

    expect(findEditor().props('value')).toBe('');
  });
});
