import { IMPORT_STATE, isInProgress } from '~/jira_import/utils';

describe('isInProgress', () => {
  it('returns true when state is IMPORT_STATE.SCHEDULED', () => {
    expect(isInProgress(IMPORT_STATE.SCHEDULED)).toBe(true);
  });

  it('returns true when state is IMPORT_STATE.STARTED', () => {
    expect(isInProgress(IMPORT_STATE.STARTED)).toBe(true);
  });

  it('returns false when state is IMPORT_STATE.FAILED', () => {
    expect(isInProgress(IMPORT_STATE.FAILED)).toBe(false);
  });

  it('returns false when state is IMPORT_STATE.FINISHED', () => {
    expect(isInProgress(IMPORT_STATE.FINISHED)).toBe(false);
  });

  it('returns false when state is IMPORT_STATE.NONE', () => {
    expect(isInProgress(IMPORT_STATE.NONE)).toBe(false);
  });

  it('returns false when state is undefined', () => {
    expect(isInProgress()).toBe(false);
  });
});
