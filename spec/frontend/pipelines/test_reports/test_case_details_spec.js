import { GlModal } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import TestCaseDetails from '~/pipelines/components/test_reports/test_case_details.vue';
import CodeBlock from '~/vue_shared/components/code_block.vue';

const localVue = createLocalVue();

describe('Test case details', () => {
  let wrapper;
  const defaultTestCase = {
    classname: 'spec.test_spec',
    name: 'Test#something cool',
    formattedTime: '10.04ms',
    recent_failures: {
      count: 2,
      base_branch: 'main',
    },
    system_output: 'Line 42 is broken',
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findName = () => wrapper.findByTestId('test-case-name');
  const findDuration = () => wrapper.findByTestId('test-case-duration');
  const findRecentFailures = () => wrapper.findByTestId('test-case-recent-failures');
  const findAttachmentUrl = () => wrapper.findByTestId('test-case-attachment-url');
  const findSystemOutput = () => wrapper.findByTestId('test-case-trace');

  const createComponent = (testCase = {}) => {
    wrapper = extendedWrapper(
      shallowMount(TestCaseDetails, {
        localVue,
        propsData: {
          modalId: 'my-modal',
          testCase: {
            ...defaultTestCase,
            ...testCase,
          },
        },
        stubs: { CodeBlock, GlModal },
      }),
    );
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
      expect(findModal().props('title')).toBe(defaultTestCase.classname);
    });

    it('renders the test case name', () => {
      expect(findName().text()).toBe(defaultTestCase.name);
    });

    it('renders the test case duration', () => {
      expect(findDuration().text()).toBe(defaultTestCase.formattedTime);
    });
  });

  describe('when test case has recent failures', () => {
    describe('has only 1 recent failure', () => {
      it('renders the recent failure', () => {
        createComponent({ recent_failures: { ...defaultTestCase.recent_failures, count: 1 } });

        expect(findRecentFailures().text()).toContain(
          `Failed 1 time in ${defaultTestCase.recent_failures.base_branch} in the last 14 days`,
        );
      });
    });

    describe('has more than 1 recent failure', () => {
      it('renders the recent failures', () => {
        createComponent();

        expect(findRecentFailures().text()).toContain(
          `Failed ${defaultTestCase.recent_failures.count} times in ${defaultTestCase.recent_failures.base_branch} in the last 14 days`,
        );
      });
    });
  });

  describe('when test case does not have recent failures', () => {
    it('does not render the recent failures', () => {
      createComponent({ recent_failures: null });

      expect(findRecentFailures().exists()).toBe(false);
    });
  });

  describe('when test case has attachment URL', () => {
    it('renders the attachment URL as a link', () => {
      const expectedUrl = '/my/path.jpg';
      createComponent({ attachment_url: expectedUrl });
      const attachmentUrl = findAttachmentUrl();

      expect(attachmentUrl.exists()).toBe(true);
      expect(attachmentUrl.attributes('href')).toBe(expectedUrl);
    });
  });

  describe('when test case does not have attachment URL', () => {
    it('does not render the attachment URL', () => {
      createComponent({ attachment_url: null });

      expect(findAttachmentUrl().exists()).toBe(false);
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
