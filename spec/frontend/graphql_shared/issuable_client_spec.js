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

  describe('WorkItem.widgets merge for LINKED_ITEMS', () => {
    const widgetsQuery = (selection) => gql`
      query {
        workItem(id: "${WORK_ITEM_ID}") {
          __typename
          id
          widgets {
            __typename
            type
            ... on WorkItemWidgetLinkedItems {
              ${selection}
            }
          }
        }
      }
    `;
    const typeOnlyQuery = widgetsQuery('type');
    const countsQuery = widgetsQuery('blockedByCount blockingCount');
    const linkedItemsQuery = widgetsQuery(
      'linkedItems { __typename nodes { __typename linkId linkType } }',
    );
    const linkedItemsWidget = (fields) => ({
      __typename: 'WorkItemWidgetLinkedItems',
      type: 'LINKED_ITEMS',
      ...fields,
    });

    let cache;

    const write = (query, fields) =>
      cache.writeQuery({
        query,
        data: {
          workItem: {
            __typename: 'WorkItem',
            id: WORK_ITEM_ID,
            widgets: [linkedItemsWidget(fields)],
          },
        },
      });

    beforeEach(() => {
      cache = new InMemoryCache(config.cacheConfig);
    });

    it('keeps incoming counts when the widget arrives without linkedItems', () => {
      write(typeOnlyQuery, {});
      write(countsQuery, { blockedByCount: 1, blockingCount: 2 });

      expect(cache.readQuery({ query: countsQuery }).workItem.widgets[0]).toMatchObject({
        blockedByCount: 1,
        blockingCount: 2,
      });
    });

    it('keeps existing linkedItems when the widget arrives without them', () => {
      write(linkedItemsQuery, {
        linkedItems: {
          __typename: 'LinkedWorkItemTypeConnection',
          nodes: [{ __typename: 'LinkedWorkItemType', linkId: '1', linkType: 'relates_to' }],
        },
      });
      write(countsQuery, { blockedByCount: 1, blockingCount: 0 });

      expect(
        cache.readQuery({ query: linkedItemsQuery }).workItem.widgets[0].linkedItems.nodes,
      ).toHaveLength(1);
      expect(cache.readQuery({ query: countsQuery })).not.toBeNull();
    });
  });
});
