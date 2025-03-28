import { transform } from '~/glql/core/transformer/data';
import * as functions from '~/glql/core/transformer/functions';
import { derivedFields } from '~/glql/core/transformer/derived_fields';

const MOCK_LABELS1 = { nodes: [{ title: 'bug' }] };
const MOCK_LABELS2 = { nodes: [{ title: 'feature' }] };

const MOCK_ISSUES = {
  issues: {
    nodes: [
      { id: '1', title: 'Lorem ipsum', labels: MOCK_LABELS1 },
      { id: '2', title: 'Dolor sit amet', labels: MOCK_LABELS2 },
    ],
  },
};

const MOCK_ISSUES_WITH_LAST_COMMENT = {
  issues: {
    nodes: [
      { id: '1', title: 'Lorem ipsum', lastComment: { nodes: [] } },
      { id: '2', title: 'Dolor sit amet', lastComment: { nodes: [{ bodyHtml: '<i>Hello</i>' }] } },
    ],
  },
};

const MOCK_MERGE_REQUESTS = {
  mergeRequests: {
    nodes: [
      { id: '1', title: 'Lorem ipsum', labels: MOCK_LABELS1 },
      { id: '2', title: 'Dolor sit amet', labels: MOCK_LABELS2 },
    ],
  },
};

const MOCK_WORK_ITEMS = {
  workItems: {
    nodes: [
      {
        id: '1',
        title: 'Lorem ipsum',
        widgets: [
          {},
          {},
          {},
          { __typename: 'WorkItemWidgetLabels', type: 'LABELS', labels: MOCK_LABELS1 },
        ],
      },
      {
        id: '2',
        title: 'Dolor sit amet',
        widgets: [
          {},
          {},
          {},
          { __typename: 'WorkItemWidgetLabels', type: 'LABELS', labels: MOCK_LABELS2 },
        ],
      },
    ],
  },
};

const MOCK_WORK_ITEMS_WITHOUT_WIDGETS = {
  workItems: {
    nodes: [
      { id: '1', title: 'Lorem ipsum' },
      { id: '2', title: 'Dolor sit amet' },
    ],
  },
};

describe('GLQL Data Transformer', () => {
  describe('transform', () => {
    it.each`
      sourceType         | mockQuery
      ${'issues'}        | ${MOCK_ISSUES}
      ${'mergeRequests'} | ${MOCK_MERGE_REQUESTS}
      ${'workItems'}     | ${MOCK_WORK_ITEMS}
    `('extracts data for $sourceType source', ({ mockQuery }) => {
      const mockData = { project: mockQuery };
      const mockConfig = {
        fields: [
          { key: 'title', name: 'title' },
          {
            key: 'labels_bug',
            name: 'labels',
            transform: functions.getFunction('labels').getTransformer('labels_bug', 'bug'),
          },
        ],
      };

      const result = transform(mockData, mockConfig);

      expect(result).toEqual({
        nodes: [
          {
            id: '1',
            title: 'Lorem ipsum',
            labels_bug: { nodes: [{ title: 'bug' }] },
            labels: { nodes: [] },
          },
          {
            id: '2',
            title: 'Dolor sit amet',
            labels_bug: { nodes: [] },
            labels: { nodes: [{ title: 'feature' }] },
          },
        ],
      });
    });

    it.each`
      fieldName        | mockQuery
      ${'lastComment'} | ${MOCK_ISSUES_WITH_LAST_COMMENT}
    `('extracts data for $fieldName field', ({ fieldName, mockQuery }) => {
      const mockData = { project: mockQuery };
      const mockConfig = {
        fields: [
          { key: 'title', name: 'title' },
          {
            key: 'lastComment',
            name: 'lastComment',
            transform: derivedFields[fieldName],
          },
        ],
      };

      const result = transform(mockData, mockConfig);

      expect(result).toEqual({
        nodes: [
          {
            id: '1',
            title: 'Lorem ipsum',
          },
          {
            id: '2',
            title: 'Dolor sit amet',
            lastComment: '<i>Hello</i>',
          },
        ],
      });
    });

    it('does not iterate over widgets if they do not exist', () => {
      const mockData = { project: MOCK_WORK_ITEMS_WITHOUT_WIDGETS };
      const mockConfig = {
        fields: [{ key: 'title', name: 'title' }],
      };

      const result = transform(mockData, mockConfig);

      expect(result).toEqual({
        nodes: [
          { id: '1', title: 'Lorem ipsum' },
          { id: '2', title: 'Dolor sit amet' },
        ],
      });
    });
  });
});
