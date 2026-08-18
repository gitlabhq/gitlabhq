import { findHierarchyWidget } from '~/work_items/utils';
import { buildFeaturesTreeResponse, workItemHierarchyPaginatedTreeResponse } from './mock_data';

describe('work items mock data helpers', () => {
  describe('buildFeaturesTreeResponse', () => {
    const widgetsResponse = workItemHierarchyPaginatedTreeResponse;
    const childIds = findHierarchyWidget(widgetsResponse.data.workItem).children.nodes.map(
      (node) => node.id,
    );

    let result;

    beforeEach(() => {
      result = buildFeaturesTreeResponse(widgetsResponse);
    });

    it('moves the hierarchy onto `workItem.features` and drops `workItem.widgets`', () => {
      const { workItem } = result.data;

      expect(workItem.widgets).toBeUndefined();
      expect(workItem.features).toHaveProperty('__typename', 'WorkItemFeatures');
      expect(workItem.features.hierarchy.type).toBe('HIERARCHY');
    });

    it('preserves the paginated children under `features.hierarchy`', () => {
      const { children } = result.data.workItem.features.hierarchy;

      expect(children.nodes.map((node) => node.id)).toEqual(childIds);
      expect(children.pageInfo).toEqual(
        findHierarchyWidget(widgetsResponse.data.workItem).children.pageInfo,
      );
    });

    it('exposes `features` on every child node instead of `widgets`', () => {
      const { nodes } = result.data.workItem.features.hierarchy.children;

      expect(nodes.length).toBeGreaterThan(0);
      nodes.forEach((node) => {
        expect(node.widgets).toBeUndefined();
        expect(node.features).toHaveProperty('__typename', 'WorkItemFeatures');
      });
    });

    it('does not mutate the source response', () => {
      expect(widgetsResponse.data.workItem.widgets).toBeDefined();
      expect(widgetsResponse.data.workItem.features).toBeUndefined();
    });
  });
});
