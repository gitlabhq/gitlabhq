import { GlAlert, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { trimText } from 'helpers/text_helper';
import CiLintWarnings from '~/ci/pipeline_editor/components/lint/ci_lint_warnings.vue';

const warnings = ['warning 1', 'warning 2', 'warning 3'];

describe('CI lint warnings', () => {
  let wrapper;

  const createComponent = (limit = 25) => {
    wrapper = shallowMountExtended(CiLintWarnings, {
      propsData: {
        warnings,
        maxWarnings: limit,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findWarningAlert = () => wrapper.findComponent(GlAlert);
  const findWarnings = () => wrapper.findAll('[data-testid="ci-lint-warning"]');
  const findWarningMessage = () => trimText(wrapper.findByTestId('warning-summary').text());

  it('displays the warning alert', () => {
    createComponent();

    expect(findWarningAlert().exists()).toBe(true);
  });

  it('displays all the warnings', () => {
    createComponent();

    expect(findWarnings()).toHaveLength(warnings.length);
  });

  it('shows the correct message when the limit is not passed', () => {
    createComponent();

    expect(findWarningMessage()).toBe(`${warnings.length} warnings found:`);
  });

  it('shows the correct message when the limit is passed', () => {
    const limit = 2;

    createComponent(limit);

    expect(findWarningMessage()).toBe(`${warnings.length} warnings found: showing first ${limit}`);
  });
});
