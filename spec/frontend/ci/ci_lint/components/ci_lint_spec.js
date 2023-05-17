import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import waitForPromises from 'helpers/wait_for_promises';
import CiLint from '~/ci/ci_lint/components/ci_lint.vue';
import CiLintResults from '~/ci/pipeline_editor/components/lint/ci_lint_results.vue';
import lintCIMutation from '~/ci/pipeline_editor/graphql/mutations/client/lint_ci.mutation.graphql';
import SourceEditor from '~/vue_shared/components/source_editor.vue';
import { mockLintDataValid } from '../mock_data';

describe('CI Lint', () => {
  let wrapper;

  const endpoint = '/namespace/project/-/ci/lint';
  const content =
    "test_job:\n  stage: build\n  script: echo 'Building'\n  only:\n    - web\n    - chat\n    - pushes\n  allow_failure: true  ";
  const mockMutate = jest.fn().mockResolvedValue(mockLintDataValid);

  const createComponent = () => {
    wrapper = shallowMount(CiLint, {
      data() {
        return {
          content,
        };
      },
      propsData: {
        endpoint,
        pipelineSimulationHelpPagePath: '/help/ci/lint#pipeline-simulation',
        lintHelpPagePath: '/help/ci/lint#anchor',
      },
      mocks: {
        $apollo: {
          mutate: mockMutate,
        },
      },
    });
  };

  const findEditor = () => wrapper.findComponent(SourceEditor);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findCiLintResults = () => wrapper.findComponent(CiLintResults);
  const findValidateBtn = () => wrapper.find('[data-testid="ci-lint-validate"]');
  const findClearBtn = () => wrapper.find('[data-testid="ci-lint-clear"]');

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    mockMutate.mockClear();
  });

  it('displays the editor', () => {
    expect(findEditor().exists()).toBe(true);
  });

  it('validate action calls mutation correctly', () => {
    findValidateBtn().vm.$emit('click');

    expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
      mutation: lintCIMutation,
      variables: { content, dry: false, endpoint },
    });
  });

  it('validate action calls mutation with dry run', async () => {
    const dryRunEnabled = true;

    // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
    // eslint-disable-next-line no-restricted-syntax
    await wrapper.setData({ dryRun: dryRunEnabled });

    findValidateBtn().vm.$emit('click');

    expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
      mutation: lintCIMutation,
      variables: { content, dry: dryRunEnabled, endpoint },
    });
  });

  it('validation displays results', async () => {
    findValidateBtn().vm.$emit('click');

    await nextTick();

    expect(findValidateBtn().props('loading')).toBe(true);

    await waitForPromises();

    expect(findCiLintResults().exists()).toBe(true);
    expect(findValidateBtn().props('loading')).toBe(false);
  });

  it('validation displays error', async () => {
    mockMutate.mockRejectedValue('Error!');

    findValidateBtn().vm.$emit('click');

    await nextTick();

    expect(findValidateBtn().props('loading')).toBe(true);

    await waitForPromises();

    expect(findCiLintResults().exists()).toBe(false);
    expect(findAlert().text()).toBe('Error!');
    expect(findValidateBtn().props('loading')).toBe(false);
  });

  it('content is cleared on clear action', async () => {
    expect(findEditor().props('value')).toBe(content);

    await findClearBtn().vm.$emit('click');

    expect(findEditor().props('value')).toBe('');
  });
});
