import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import TestCaseDetails from '~/pipelines/components/test_reports/test_case_details.vue';
import CodeBlock from '~/vue_shared/components/code_block.vue';

const localVue = createLocalVue();

describe('Test case details', () => {
  let wrapper;
  const defaultTestCase = {
    classname: 'spec.test_spec',
    name: 'Test#something cool',
    formattedTime: '10.04ms',
    system_output: 'Line 42 is broken',
  };

  const findModal = () => wrapper.find(GlModal);
  const findName = () => wrapper.find('[data-testid="test-case-name"]');
  const findDuration = () => wrapper.find('[data-testid="test-case-duration"]');
  const findSystemOutput = () => wrapper.find('[data-testid="test-case-trace"]');

  const createComponent = (testCase = {}) => {
    wrapper = shallowMount(TestCaseDetails, {
      localVue,
      propsData: {
        modalId: 'my-modal',
        testCase: {
          ...defaultTestCase,
          ...testCase,
        },
      },
      stubs: { CodeBlock, GlModal },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('required details', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the test case classname as modal title', () => {
      expect(findModal().attributes('title')).toBe(defaultTestCase.classname);
    });

    it('renders the test case name', () => {
      expect(findName().text()).toBe(defaultTestCase.name);
    });

    it('renders the test case duration', () => {
      expect(findDuration().text()).toBe(defaultTestCase.formattedTime);
    });
  });

  describe('when test case has system output', () => {
    it('renders the test case system output', () => {
      createComponent();

      expect(findSystemOutput().text()).toContain(defaultTestCase.system_output);
    });
  });

  describe('when test case does not have system output', () => {
    it('does not render the test case system output', () => {
      createComponent({ system_output: null });

      expect(findSystemOutput().exists()).toBe(false);
    });
  });
});
