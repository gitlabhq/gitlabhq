import { pactWith } from 'jest-pact';

import { UpdatePipelineSchedule } from '../../../fixtures/project/pipeline_schedules/update_pipeline_schedule.fixture';
import { updatePipelineSchedule } from '../../../resources/api/pipeline_schedules';

const CONSUMER_NAME = 'PipelineSchedules#edit';
const CONSUMER_LOG = '../logs/consumer.log';
const CONTRACT_DIR = '../contracts/project/pipeline_schedules/edit';
const PROVIDER_NAME = 'PUT edit a pipeline schedule';

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
          ...UpdatePipelineSchedule.scenario,
          ...UpdatePipelineSchedule.request,
          willRespondWith: UpdatePipelineSchedule.success,
        };

        provider.addInteraction(interaction);
      });

      it('returns a successful body', async () => {
        const pipelineSchedule = await updatePipelineSchedule({
          url: provider.mockService.baseUrl,
        });

        expect(pipelineSchedule.status).toEqual(UpdatePipelineSchedule.success.status);
      });
    });
  },
);
