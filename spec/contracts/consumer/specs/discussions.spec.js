'use strict';

const { pactWith } = require('jest-pact');

const { Discussions } = require('../fixtures/discussions.fixture');
const { getDiscussions } = require('../endpoints/merge_requests');

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
