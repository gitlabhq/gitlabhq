import { STATUSES } from '~/import_entities/constants';
import {
  isFinished,
  isAvailableForImport,
  isProjectCreationAllowed,
} from '~/import_entities/import_groups/utils';

const FINISHED_STATUSES = [STATUSES.FINISHED, STATUSES.FAILED, STATUSES.TIMEOUT];
const OTHER_STATUSES = Object.values(STATUSES).filter(
  (status) => !FINISHED_STATUSES.includes(status),
);
describe('Direct transfer status utils', () => {
  describe('isFinished', () => {
    it.each(FINISHED_STATUSES.map((s) => [s]))(
      'reports group as finished when import status is %s',
      (status) => {
        expect(isFinished({ progress: { status } })).toBe(true);
      },
    );

    it.each(OTHER_STATUSES.map((s) => [s]))(
      'does not report group as finished when import status is %s',
      (status) => {
        expect(isFinished({ progress: { status } })).toBe(false);
      },
    );

    it('does not report group as finished when there is no progress', () => {
      expect(isFinished({ progress: null })).toBe(false);
    });

    it('does not report group as finished when status is unknown', () => {
      expect(isFinished({ progress: { status: 'weird' } })).toBe(false);
    });
  });

  describe('isAvailableForImport', () => {
    it.each(FINISHED_STATUSES.map((s) => [s]))(
      'reports group as available for import when status is %s',
      (status) => {
        expect(isAvailableForImport({ progress: { status } })).toBe(true);
      },
    );

    it.each(OTHER_STATUSES.map((s) => [s]))(
      'does not report group as not available for import when status is %s',
      (status) => {
        expect(isAvailableForImport({ progress: { status } })).toBe(false);
      },
    );

    it('reports group as available for import when there is no progress', () => {
      expect(isAvailableForImport({ progress: null })).toBe(true);
    });

    it('reports group as finished when status is unknown', () => {
      expect(isFinished({ progress: { status: 'weird' } })).toBe(false);
    });
  });

  describe('isProjectCreationAllowed', () => {
    it.each`
      projectCreationLevel | expected
      ${null}              | ${false}
      ${'noone'}           | ${false}
      ${'developer'}       | ${true}
      ${'maintainer'}      | ${true}
    `(
      'when projectCreationLevel is $projectCreationLevel, returns $expected',
      ({ projectCreationLevel, expected }) => {
        expect(isProjectCreationAllowed({ projectCreationLevel })).toBe(expected);
      },
    );

    it('when "No parent" is selected, returns true', () => {
      expect(isProjectCreationAllowed({ fullPath: '' })).toBe(true);
    });
  });
});
