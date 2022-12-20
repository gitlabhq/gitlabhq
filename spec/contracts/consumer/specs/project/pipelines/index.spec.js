import { pactWith } from 'jest-pact';

import { ProjectPipelines } from '../../../fixtures/project/pipelines/get_list_project_pipelines.fixture';
import { getProjectPipelines } from '../../../resources/api/project/pipelines';

const CONSUMER_NAME = 'Pipelines#index';
const CONSUMER_LOG = '../logs/consumer.log';
const CONTRACT_DIR = '../contracts/project/pipelines/index';
const PROVIDER_NAME = 'GET list project pipelines';

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
          ...ProjectPipelines.scenario,
          ...ProjectPipelines.request,
          willRespondWith: ProjectPipelines.success,
        };
        provider.addInteraction(interaction);
      });

      it('returns a successful body', async () => {
        const pipelines = await getProjectPipelines({
          url: provider.mockService.baseUrl,
        });

        expect(pipelines).toEqual(ProjectPipelines.body);
      });
    });
  },
);
