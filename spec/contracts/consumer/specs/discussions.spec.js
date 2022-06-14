/* eslint-disable @gitlab/require-i18n-strings */

import { pactWith } from 'jest-pact';

import { Discussions } from '../fixtures/discussions.fixture';
import { getDiscussions } from '../endpoints/merge_requests';

pactWith(
  {
    consumer: 'Merge Request Page',
    provider: 'Merge Request Discussions Endpoint',
    log: '../logs/consumer.log',
    dir: '../contracts',
  },

  (provider) => {
    describe('Discussions Endpoint', () => {
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
/* eslint-enable @gitlab/require-i18n-strings */
