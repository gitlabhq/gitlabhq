import { GlAlert, GlLink } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import CiLint from '~/pipeline_editor/components/lint/ci_lint.vue';
import { mergeUnwrappedCiConfig, mockLintHelpPagePath } from '../../mock_data';

describe('~/pipeline_editor/components/lint/ci_lint.vue', () => {
  let wrapper;

  const createComponent = ({ props, mountFn = shallowMount } = {}) => {
    wrapper = mountFn(CiLint, {
      provide: {
        lintHelpPagePath: mockLintHelpPagePath,
      },
      propsData: {
        ciConfig: mergeUnwrappedCiConfig(),
        ...props,
      },
    });
  };

  const findAllByTestId = (selector) => wrapper.findAll(`[data-testid="${selector}"]`);
  const findAlert = () => wrapper.find(GlAlert);
  const findLintParameters = () => findAllByTestId('ci-lint-parameter');
  const findLintParameterAt = (i) => findLintParameters().at(i);
  const findLintValueAt = (i) => findAllByTestId('ci-lint-value').at(i);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Valid Results', () => {
    beforeEach(() => {
      createComponent({ props: { isValid: true }, mountFn: mount });
    });

    it('displays valid results', () => {
      expect(findAlert().text()).toMatch('Status: Syntax is correct.');
    });

    it('displays link to the right help page', () => {
      expect(findAlert().find(GlLink).attributes('href')).toBe(mockLintHelpPagePath);
    });

    it('displays jobs', () => {
      expect(findLintParameters()).toHaveLength(3);

      expect(findLintParameterAt(0).text()).toBe('Test Job - job_test_1');
      expect(findLintParameterAt(1).text()).toBe('Test Job - job_test_2');
      expect(findLintParameterAt(2).text()).toBe('Build Job - job_build');
    });

    it('displays jobs details', () => {
      expect(findLintParameters()).toHaveLength(3);

      expect(findLintValueAt(0).text()).toMatchInterpolatedText(
        'echo "test 1" Only policy: branches, tags When: on_success',
      );
      expect(findLintValueAt(1).text()).toMatchInterpolatedText(
        'echo "test 2" Only policy: branches, tags When: on_success',
      );
      expect(findLintValueAt(2).text()).toMatchInterpolatedText(
        'echo "build" Only policy: branches, tags When: on_success',
      );
    });

    it('displays invalid results', () => {
      createComponent({ props: { isValid: false }, mountFn: mount });

      expect(findAlert().text()).toMatch('Status: Syntax is incorrect.');
    });
  });
});
