import { within } from '@testing-library/dom';
import { mount } from '@vue/test-utils';
import { merge } from 'lodash';
import { TEST_HOST } from 'helpers/test_constants';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import CodeSnippetAlert from '~/ci/pipeline_editor/components/code_snippet_alert/code_snippet_alert.vue';
import { CODE_SNIPPET_SOURCE_API_FUZZING } from '~/ci/pipeline_editor/components/code_snippet_alert/constants';

const apiFuzzingConfigurationPath = '/namespace/project/-/security/configuration/api_fuzzing';

describe('EE - CodeSnippetAlert', () => {
  let wrapper;

  const createWrapper = (options) => {
    wrapper = extendedWrapper(
      mount(
        CodeSnippetAlert,
        merge(
          {
            provide: {
              configurationPaths: {
                [CODE_SNIPPET_SOURCE_API_FUZZING]: apiFuzzingConfigurationPath,
              },
            },
            propsData: {
              source: CODE_SNIPPET_SOURCE_API_FUZZING,
            },
          },
          options,
        ),
      ),
    );
  };

  const withinComponent = () => within(wrapper.element);
  const findDocsLink = () => withinComponent().getByRole('link', { name: /read documentation/i });
  const findConfigurationLink = () =>
    withinComponent().getByRole('link', { name: /Go back to configuration/i });

  beforeEach(() => {
    createWrapper();
  });

  it("provides a link to the feature's documentation", () => {
    const docsLink = findDocsLink();

    expect(docsLink).not.toBe(null);
    expect(docsLink.href).toBe(`${TEST_HOST}/help/user/application_security/api_fuzzing/_index`);
  });

  it("provides a link to the feature's configuration form", () => {
    const configurationLink = findConfigurationLink();

    expect(configurationLink).not.toBe(null);
    expect(configurationLink.href).toBe(TEST_HOST + apiFuzzingConfigurationPath);
  });
});
