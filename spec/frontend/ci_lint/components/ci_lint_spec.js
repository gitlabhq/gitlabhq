import { shallowMount } from '@vue/test-utils';
import EditorLite from '~/vue_shared/components/editor_lite.vue';
import CiLint from '~/ci_lint/components/ci_lint.vue';
import lintCIMutation from '~/ci_lint/graphql/mutations/lint_ci.mutation.graphql';

describe('CI Lint', () => {
  let wrapper;

  const endpoint = '/namespace/project/-/ci/lint';
  const content =
    "test_job:\n  stage: build\n  script: echo 'Building'\n  only:\n    - web\n    - chat\n    - pushes\n  allow_failure: true  ";

  const createComponent = () => {
    wrapper = shallowMount(CiLint, {
      data() {
        return {
          content,
        };
      },
      propsData: {
        endpoint,
        helpPagePath: '/help/ci/lint#pipeline-simulation',
      },
      mocks: {
        $apollo: {
          mutate: jest.fn(),
        },
      },
    });
  };

  const findEditor = () => wrapper.find(EditorLite);
  const findValidateBtn = () => wrapper.find('[data-testid="ci-lint-validate"]');
  const findClearBtn = () => wrapper.find('[data-testid="ci-lint-clear"]');

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
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

    await wrapper.setData({ dryRun: dryRunEnabled });

    findValidateBtn().vm.$emit('click');

    expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
      mutation: lintCIMutation,
      variables: { content, dry: dryRunEnabled, endpoint },
    });
  });

  it('content is cleared on clear action', async () => {
    expect(findEditor().props('value')).toBe(content);

    await findClearBtn().vm.$emit('click');

    expect(findEditor().props('value')).toBe('');
  });
});
