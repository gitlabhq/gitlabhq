/* eslint-disable @gitlab/require-i18n-strings */

import { pactWith } from 'jest-pact';

import { Diffs } from '../fixtures/diffs.fixture';
import { getDiffs } from '../endpoints/merge_requests';

pactWith(
  {
    consumer: 'Merge Request Page',
    provider: 'Merge Request Diffs Endpoint',
    log: '../logs/consumer.log',
    dir: '../contracts',
  },

  (provider) => {
    describe('Diffs Endpoint', () => {
      beforeEach(() => {
        const interaction = {
          state: 'a merge request with diffs exists',
          ...Diffs.request,
          willRespondWith: Diffs.success,
        };
        provider.addInteraction(interaction);
      });

      it('return a successful body', () => {
        return getDiffs({
          url: provider.mockService.baseUrl,
        }).then((diffs) => {
          expect(diffs).toEqual(Diffs.body);
        });
      });
    });
  },
);
/* eslint-enable @gitlab/require-i18n-strings */
