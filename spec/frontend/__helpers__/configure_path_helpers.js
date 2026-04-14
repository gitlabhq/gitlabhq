import { configure, config } from '~/lib/utils/path_helpers/core';

export const useConfigurePathHelpers = (relativeUrlRoot) => {
  let originalConfig;

  beforeEach(() => {
    originalConfig = config();
    configure({ default_url_options: { script_name: relativeUrlRoot } });
  });

  afterEach(() => {
    configure(originalConfig);
  });
};
