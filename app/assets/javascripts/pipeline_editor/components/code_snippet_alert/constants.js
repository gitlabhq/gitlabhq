import { helpPagePath } from '~/helpers/help_page_helper';

export const CODE_SNIPPET_SOURCE_URL_PARAM = 'code_snippet_copied_from';
export const CODE_SNIPPET_SOURCE_API_FUZZING = 'api_fuzzing';
export const CODE_SNIPPET_SOURCE_DAST = 'dast';

export const CODE_SNIPPET_SOURCES = [CODE_SNIPPET_SOURCE_API_FUZZING, CODE_SNIPPET_SOURCE_DAST];
export const CODE_SNIPPET_SOURCE_SETTINGS = {
  [CODE_SNIPPET_SOURCE_API_FUZZING]: {
    datasetKey: 'apiFuzzingConfigurationPath',
    docsPath: helpPagePath('user/application_security/api_fuzzing/index'),
  },
  [CODE_SNIPPET_SOURCE_DAST]: {
    datasetKey: 'dastConfigurationPath',
    docsPath: helpPagePath('user/application_security/dast/index'),
  },
};
