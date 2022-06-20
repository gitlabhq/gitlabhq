/* eslint-disable @gitlab/require-i18n-strings */

import { pactWith } from 'jest-pact';

import { DiffsBatch } from '../../../fixtures/project/merge_request/diffs_batch.fixture';
import { Discussions } from '../../../fixtures/project/merge_request/discussions.fixture';
import { DiffsMetadata } from '../../../fixtures/project/merge_request/diffs_metadata.fixture';
import {
  getDiffsBatch,
  getDiffsMetadata,
  getDiscussions,
} from '../../../endpoints/project/merge_requests';

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
          state: 'a merge request with diffs exists',
          ...DiffsBatch.request,
          willRespondWith: DiffsBatch.success,
        };
        provider.addInteraction(interaction);
      });

      it('returns a successful body', () => {
        return getDiffsBatch({
          url: provider.mockService.baseUrl,
        }).then((diffsBatch) => {
          expect(diffsBatch).toEqual(DiffsBatch.body);
        });
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
          state: 'a merge request with discussions exists',
          ...Discussions.request,
          willRespondWith: Discussions.success,
        };
        provider.addInteraction(interaction);
      });

      it('return a successful body', () => {
        return getDiscussions({
          url: provider.mockService.baseUrl,
        }).then((discussions) => {
          expect(discussions).toEqual(Discussions.body);
        });
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
          state: 'a merge request exists',
          ...DiffsMetadata.request,
          willRespondWith: DiffsMetadata.success,
        };
        provider.addInteraction(interaction);
      });

      it('return a successful body', () => {
        return getDiffsMetadata({
          url: provider.mockService.baseUrl,
        }).then((diffsMetadata) => {
          expect(diffsMetadata).toEqual(DiffsMetadata.body);
        });
      });
    });
  },
);

/* eslint-enable @gitlab/require-i18n-strings */
