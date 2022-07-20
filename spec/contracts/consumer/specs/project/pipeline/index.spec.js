/* eslint-disable @gitlab/require-i18n-strings */

import { pactWith } from 'jest-pact';

import { ProjectPipelines } from '../../../fixtures/project/pipeline/get_list_project_pipelines.fixture';
import { getProjectPipelines } from '../../../endpoints/project/pipelines';

const CONSUMER_NAME = 'Pipelines#index';
const CONSUMER_LOG = '../logs/consumer.log';
const CONTRACT_DIR = '../contracts/project/pipeline/index';
const PROVIDER_NAME = 'GET List project pipelines';

// API endpoint: /pipelines.json
pactWith(
  {
    consumer: CONSUMER_NAME,
    provider: PROVIDER_NAME,
    log: CONSUMER_LOG,
    dir: CONTRACT_DIR,
  },

  (provider) => {
    describe(PROVIDER_NAME, () => {
      beforeEach(() => {
        const interaction = {
          state: 'a few pipelines for a project exists',
          ...ProjectPipelines.request,
          willRespondWith: ProjectPipelines.success,
        };
        provider.addInteraction(interaction);
      });

      it('returns a successful body', () => {
        return getProjectPipelines({
          url: provider.mockService.baseUrl,
        }).then((pipelines) => {
          expect(pipelines).toEqual(ProjectPipelines.body);
        });
      });
    });
  },
);

/* eslint-enable @gitlab/require-i18n-strings */
