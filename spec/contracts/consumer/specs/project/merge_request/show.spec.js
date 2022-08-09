import { pactWith } from 'jest-pact';

import { DiffsBatch } from '../../../fixtures/project/merge_request/diffs_batch.fixture';
import { Discussions } from '../../../fixtures/project/merge_request/discussions.fixture';
import { DiffsMetadata } from '../../../fixtures/project/merge_request/diffs_metadata.fixture';
import {
  getDiffsBatch,
  getDiffsMetadata,
  getDiscussions,
} from '../../../resources/api/project/merge_requests';

const CONSUMER_NAME = 'MergeRequest#show';
const CONSUMER_LOG = '../logs/consumer.log';
const CONTRACT_DIR = '../contracts/project/merge_request/show';
const DIFFS_BATCH_PROVIDER_NAME = 'Merge Request Diffs Batch Endpoint';
const DISCUSSIONS_PROVIDER_NAME = 'Merge Request Discussions Endpoint';
const DIFFS_METADATA_PROVIDER_NAME = 'Merge Request Diffs Metadata Endpoint';

// API endpoint: /merge_requests/:id/diffs_batch.json
pactWith(
  {
    consumer: CONSUMER_NAME,
    provider: DIFFS_BATCH_PROVIDER_NAME,
    log: CONSUMER_LOG,
    dir: CONTRACT_DIR,
  },

  (provider) => {
    describe(DIFFS_BATCH_PROVIDER_NAME, () => {
      beforeEach(() => {
        const interaction = {
          ...DiffsBatch.scenario,
          ...DiffsBatch.request,
          willRespondWith: DiffsBatch.success,
        };
        provider.addInteraction(interaction);
      });

      it('returns a successful body', async () => {
        const diffsBatch = await getDiffsBatch({
          url: provider.mockService.baseUrl,
        });

        expect(diffsBatch).toEqual(DiffsBatch.body);
      });
    });
  },
);

pactWith(
  {
    consumer: CONSUMER_NAME,
    provider: DISCUSSIONS_PROVIDER_NAME,
    log: CONSUMER_LOG,
    dir: CONTRACT_DIR,
  },

  (provider) => {
    describe(DISCUSSIONS_PROVIDER_NAME, () => {
      beforeEach(() => {
        const interaction = {
          ...Discussions.scenario,
          ...Discussions.request,
          willRespondWith: Discussions.success,
        };
        provider.addInteraction(interaction);
      });

      it('return a successful body', async () => {
        const discussions = await getDiscussions({
          url: provider.mockService.baseUrl,
        });

        expect(discussions).toEqual(Discussions.body);
      });
    });
  },
);

pactWith(
  {
    consumer: CONSUMER_NAME,
    provider: DIFFS_METADATA_PROVIDER_NAME,
    log: CONSUMER_LOG,
    dir: CONTRACT_DIR,
  },

  (provider) => {
    describe(DIFFS_METADATA_PROVIDER_NAME, () => {
      beforeEach(() => {
        const interaction = {
          ...DiffsMetadata.scenario,
          ...DiffsMetadata.request,
          willRespondWith: DiffsMetadata.success,
        };
        provider.addInteraction(interaction);
      });

      it('return a successful body', async () => {
        const diffsMetadata = await getDiffsMetadata({
          url: provider.mockService.baseUrl,
        });

        expect(diffsMetadata).toEqual(DiffsMetadata.body);
      });
    });
  },
);
