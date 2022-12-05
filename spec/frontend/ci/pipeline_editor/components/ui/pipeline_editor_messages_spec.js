import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import setWindowLocation from 'helpers/set_window_location_helper';
import { TEST_HOST } from 'helpers/test_constants';
import CodeSnippetAlert from '~/ci/pipeline_editor/components/code_snippet_alert/code_snippet_alert.vue';
import { CODE_SNIPPET_SOURCES } from '~/ci/pipeline_editor/components/code_snippet_alert/constants';
import PipelineEditorMessages from '~/ci/pipeline_editor/components/ui/pipeline_editor_messages.vue';
import {
  COMMIT_FAILURE,
  COMMIT_SUCCESS,
  COMMIT_SUCCESS_WITH_REDIRECT,
  DEFAULT_FAILURE,
  DEFAULT_SUCCESS,
  LOAD_FAILURE_UNKNOWN,
  PIPELINE_FAILURE,
} from '~/ci/pipeline_editor/constants';

beforeEach(() => {
  setWindowLocation(TEST_HOST);
});

describe('Pipeline Editor messages', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(PipelineEditorMessages, {
      propsData: props,
    });
  };

  const findCodeSnippetAlert = () => wrapper.findComponent(CodeSnippetAlert);
  const findAlert = () => wrapper.findComponent(GlAlert);

  describe('success alert', () => {
    it('shows a message for successful commit type', () => {
      createComponent({ successType: COMMIT_SUCCESS, showSuccess: true });

      expect(findAlert().text()).toBe(wrapper.vm.$options.success[COMMIT_SUCCESS]);
    });

    it('shows a message for successful commit with redirect type', () => {
      createComponent({ successType: COMMIT_SUCCESS_WITH_REDIRECT, showSuccess: true });

      expect(findAlert().text()).toBe(wrapper.vm.$options.success[COMMIT_SUCCESS_WITH_REDIRECT]);
    });

    it('does not show alert when there is a successType but visibility is off', () => {
      createComponent({ successType: COMMIT_SUCCESS, showSuccess: false });

      expect(findAlert().exists()).toBe(false);
    });

    it('shows a success alert with default copy if `showSuccess` is true and the `successType` is not valid,', () => {
      createComponent({ successType: 'random', showSuccess: true });

      expect(findAlert().text()).toBe(wrapper.vm.$options.success[DEFAULT_SUCCESS]);
    });

    it('emit `hide-success` event when clicking on the dismiss button', async () => {
      const expectedEvent = 'hide-success';

      createComponent({ successType: COMMIT_SUCCESS, showSuccess: true });
      expect(wrapper.emitted(expectedEvent)).not.toBeDefined();

      await findAlert().vm.$emit('dismiss');

      expect(wrapper.emitted(expectedEvent)).toBeDefined();
    });
  });

  describe('failure alert', () => {
    it.each`
      failureType             | message                             | expectedFailureType
      ${COMMIT_FAILURE}       | ${'failed commit'}                  | ${COMMIT_FAILURE}
      ${LOAD_FAILURE_UNKNOWN} | ${'loading failure'}                | ${LOAD_FAILURE_UNKNOWN}
      ${PIPELINE_FAILURE}     | ${'pipeline failure'}               | ${PIPELINE_FAILURE}
      ${'random'}             | ${'error without a specified type'} | ${DEFAULT_FAILURE}
    `('shows a message for $message', ({ failureType, expectedFailureType }) => {
      createComponent({ failureType, showFailure: true });

      expect(findAlert().text()).toBe(wrapper.vm.$options.errors[expectedFailureType]);
    });

    it('show failure reasons when there are some', () => {
      const failureReasons = ['There was a problem', 'ouppps'];
      createComponent({ failureType: COMMIT_FAILURE, failureReasons, showFailure: true });

      expect(wrapper.html()).toContain(failureReasons[0]);
      expect(wrapper.html()).toContain(failureReasons[1]);
    });

    it('does not show a message for error with a disabled visibility', () => {
      createComponent({ failureType: 'random', showFailure: false });

      expect(findAlert().exists()).toBe(false);
    });

    it('emit `hide-failure` event when clicking on the dismiss button', async () => {
      const expectedEvent = 'hide-failure';

      createComponent({ failureType: COMMIT_FAILURE, showFailure: true });
      expect(wrapper.emitted(expectedEvent)).not.toBeDefined();

      await findAlert().vm.$emit('dismiss');

      expect(wrapper.emitted(expectedEvent)).toBeDefined();
    });
  });

  describe('code snippet alert', () => {
    const setCodeSnippetUrlParam = (value) => {
      setWindowLocation(`${TEST_HOST}/?code_snippet_copied_from=${value}`);
    };

    it('does not show by default', () => {
      createComponent();

      expect(findCodeSnippetAlert().exists()).toBe(false);
    });

    it.each(CODE_SNIPPET_SOURCES)('shows if URL param is %s, and cleans up URL', (source) => {
      jest.spyOn(window.history, 'replaceState');
      setCodeSnippetUrlParam(source);
      createComponent();

      expect(findCodeSnippetAlert().exists()).toBe(true);
      expect(window.history.replaceState).toHaveBeenCalledWith({}, document.title, `${TEST_HOST}/`);
    });

    it('does not show if URL param is invalid', () => {
      setCodeSnippetUrlParam('foo_bar');
      createComponent();

      expect(findCodeSnippetAlert().exists()).toBe(false);
    });

    it('disappears on dismiss', async () => {
      setCodeSnippetUrlParam('api_fuzzing');
      createComponent();
      const alert = findCodeSnippetAlert();

      expect(alert.exists()).toBe(true);

      await alert.vm.$emit('dismiss');

      expect(alert.exists()).toBe(false);
    });
  });
});
