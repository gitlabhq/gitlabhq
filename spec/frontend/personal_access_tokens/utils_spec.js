import {
  timeFormattedAsDate,
  timeFormattedAsDateFull,
  groupPermissionsByResourceAndCategory,
} from '~/personal_access_tokens/utils';
import { mockGroupPermissions } from './mock_data';

describe('personal_access_tokens/utils', () => {
  describe('timeFormattedAsDate', () => {
    it.each([null, undefined, ''])('returns `Never` label when time is %p', (value) => {
      expect(timeFormattedAsDate(value)).toBe('Never');
    });

    it('formats date when time is provided', () => {
      expect(timeFormattedAsDate('2025-12-01T00:00:00Z')).toBe('Dec 1, 2025');
    });

    it('handles different date formats', () => {
      expect(timeFormattedAsDate('2025-12-01')).toBe('Dec 1, 2025');
    });
  });

  describe('timeFormattedAsDateFull', () => {
    it.each([null, undefined, ''])('returns `Never` label when time is %p', (value) => {
      expect(timeFormattedAsDateFull(value)).toBe('Never');
    });

    it('formats date when time is provided', () => {
      expect(timeFormattedAsDateFull('2025-12-01T00:00:00Z')).toBe(
        'December 1, 2025 at 12:00:00 AM GMT',
      );
    });

    it('handles different date formats', () => {
      expect(timeFormattedAsDateFull('2025-12-01')).toBe('December 1, 2025 at 12:00:00 AM GMT');
    });
  });

  describe('groupPermissionsByResourceAndCategory', () => {
    it('groups permissions by resources and category', () => {
      expect(groupPermissionsByResourceAndCategory(mockGroupPermissions)).toEqual([
        {
          key: 'groups_and_projects',
          name: 'Groups and projects',
          resources: [
            {
              description: 'Project resource description',
              key: 'project',
              name: 'Project',
            },
          ],
        },
        {
          key: 'merge_request',
          name: 'Merge request',
          resources: [
            {
              description: 'Repository resource description',
              key: 'repository',
              name: 'Repository',
            },
          ],
        },
      ]);
    });
  });
});
