'use strict';

const { pactWith } = require('jest-pact');

const { Diffs } = require('../fixtures/diffs.fixture');
const { getDiffs } = require('../endpoints/merge_request');

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
          ...Diffs.request,
          willRespondWith: Diffs.success,
        };
        return provider.addInteraction(interaction);
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
