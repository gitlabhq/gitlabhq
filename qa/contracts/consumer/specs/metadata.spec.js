'use strict';

const { pactWith } = require('jest-pact');

const { Metadata } = require('../fixtures/metadata.fixture');
const { getMetadata } = require('../endpoints/merge_request');

pactWith(
  {
    consumer: 'Merge Request Page',
    provider: 'Merge Request Metadata Endpoint',
    log: '../logs/consumer.log',
    dir: '../contracts',
  },

  (provider) => {
    describe('Metadata Endpoint', () => {
      beforeEach(() => {
        const interaction = {
          ...Metadata.request,
          willRespondWith: Metadata.success,
        };
        return provider.addInteraction(interaction);
      });

      it('return a successful body', () => {
        return getMetadata({
          url: provider.mockService.baseUrl,
        }).then((metadata) => {
          expect(metadata).toEqual(Metadata.body);
        });
      });
    });
  },
);
