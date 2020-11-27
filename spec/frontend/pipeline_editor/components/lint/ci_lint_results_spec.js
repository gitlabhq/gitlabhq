import { shallowMount, mount } from '@vue/test-utils';
import { GlTable, GlLink } from '@gitlab/ui';
import CiLintResults from '~/pipeline_editor/components/lint/ci_lint_results.vue';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { mockJobs, mockErrors, mockWarnings } from '../../mock_data';

describe('CI Lint Results', () => {
  let wrapper;
  const defaultProps = {
    valid: true,
    jobs: mockJobs,
    errors: [],
    warnings: [],
    dryRun: false,
    lintHelpPagePath: '/help',
  };

  const createComponent = (props = {}, mountFn = shallowMount) => {
    wrapper = mountFn(CiLintResults, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findTable = () => wrapper.find(GlTable);
  const findByTestId = selector => () => wrapper.find(`[data-testid="ci-lint-${selector}"]`);
  const findAllByTestId = selector => () => wrapper.findAll(`[data-testid="ci-lint-${selector}"]`);
  const findLinkToDoc = () => wrapper.find(GlLink);
  const findErrors = findByTestId('errors');
  const findWarnings = findByTestId('warnings');
  const findStatus = findByTestId('status');
  const findOnlyExcept = findByTestId('only-except');
  const findLintParameters = findAllByTestId('parameter');
  const findBeforeScripts = findAllByTestId('before-script');
  const findScripts = findAllByTestId('script');
  const findAfterScripts = findAllByTestId('after-script');
  const filterEmptyScripts = property => mockJobs.filter(job => job[property].length !== 0);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('Invalid results', () => {
    beforeEach(() => {
      createComponent({ valid: false, errors: mockErrors, warnings: mockWarnings }, mount);
    });

    it('does not display the table', () => {
      expect(findTable().exists()).toBe(false);
    });

    it('displays the invalid status', () => {
      expect(findStatus().text()).toContain(`Status: ${wrapper.vm.$options.incorrect.text}`);
      expect(findStatus().props('variant')).toBe(wrapper.vm.$options.incorrect.variant);
    });

    it('contains the link to documentation', () => {
      expect(findLinkToDoc().text()).toBe('More information');
      expect(findLinkToDoc().attributes('href')).toBe(defaultProps.lintHelpPagePath);
    });

    it('displays the error message', () => {
      const [expectedError] = mockErrors;

      expect(findErrors().text()).toBe(expectedError);
    });

    it('displays the warning message', () => {
      const [expectedWarning] = mockWarnings;

      expect(findWarnings().exists()).toBe(true);
      expect(findWarnings().text()).toContain(expectedWarning);
    });
  });

  describe('Valid results with dry run', () => {
    beforeEach(() => {
      createComponent({ dryRun: true }, mount);
    });

    it('displays table', () => {
      expect(findTable().exists()).toBe(true);
    });

    it('displays the valid status', () => {
      expect(findStatus().text()).toContain(wrapper.vm.$options.correct.text);
      expect(findStatus().props('variant')).toBe(wrapper.vm.$options.correct.variant);
    });

    it('does not display only/expect values with dry run', () => {
      expect(findOnlyExcept().exists()).toBe(false);
    });

    it('contains the link to documentation', () => {
      expect(findLinkToDoc().text()).toBe('More information');
      expect(findLinkToDoc().attributes('href')).toBe(defaultProps.lintHelpPagePath);
    });
  });

  describe('Lint results', () => {
    beforeEach(() => {
      createComponent({}, mount);
    });

    it('formats parameter value', () => {
      findLintParameters().wrappers.forEach((job, index) => {
        const { stage } = mockJobs[index];
        const { name } = mockJobs[index];

        expect(job.text()).toBe(`${capitalizeFirstCharacter(stage)} Job - ${name}`);
      });
    });

    it('only shows before scripts when data is present', () => {
      expect(findBeforeScripts()).toHaveLength(filterEmptyScripts('beforeScript').length);
    });

    it('only shows script when data is present', () => {
      expect(findScripts()).toHaveLength(filterEmptyScripts('script').length);
    });

    it('only shows after script when data is present', () => {
      expect(findAfterScripts()).toHaveLength(filterEmptyScripts('afterScript').length);
    });
  });
});
