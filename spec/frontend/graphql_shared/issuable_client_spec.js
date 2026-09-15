import { InMemoryCache } from '@apollo/client/core';
import gql from 'graphql-tag';
import { config } from '~/graphql_shared/issuable_client';
import { WORK_ITEM_ID, workItemFeaturesData, workItemFeaturesMergeScenarios } from './mock_data';

const featuresQuery = (widget, selection) => gql`
  query {
    workItem(id: "${WORK_ITEM_ID}") {
      __typename
      id
      features {
        __typename
        ${widget} {
          __typename
          ${selection}
        }
      }
    }
  }
`;

describe('issuable_client cache config', () => {
  describe('WorkItem.features merge', () => {
    let cache;

    beforeEach(() => {
      cache = new InMemoryCache(config.cacheConfig);
    });

    describe.each(workItemFeaturesMergeScenarios)(
      '$widget written by two documents',
      ({ widget, typename, dataSelection, dataValue, partialSelection, partialValue }) => {
        const dataQuery = featuresQuery(widget, dataSelection);
        const partialQuery = featuresQuery(widget, partialSelection);
        const write = (query, value) =>
          cache.writeQuery({ query, data: workItemFeaturesData({ widget, typename, value }) });

        it('keeps both documents when the partial one writes last', () => {
          write(dataQuery, dataValue);
          write(partialQuery, partialValue);

          expect(cache.readQuery({ query: dataQuery })).not.toBeNull();
          expect(cache.readQuery({ query: partialQuery })).not.toBeNull();
        });

        it('keeps both documents when the partial one writes first', () => {
          write(partialQuery, partialValue);
          write(dataQuery, dataValue);

          expect(cache.readQuery({ query: dataQuery })).not.toBeNull();
          expect(cache.readQuery({ query: partialQuery })).not.toBeNull();
        });

        it('replaces the widget when it arrives as null, so clearing still works', () => {
          write(dataQuery, dataValue);
          write(partialQuery, null);

          expect(cache.readQuery({ query: partialQuery }).workItem.features[widget]).toBeNull();
        });
      },
    );
  });
});
