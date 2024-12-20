import { issuableInitialDataById, isLegacyIssueType } from '~/issues/show/utils/issuable_data';

describe('issuableInitialDataById', () => {
  beforeEach(() => {
    // Clear the document body before each test
    document.body.innerHTML = '';
  });

  it('returns null when element is not found', () => {
    expect(issuableInitialDataById('non-existent')).toBeNull();
  });

  it('returns null when dataset.initial is not present', () => {
    document.body.innerHTML = '<div id="test-element"></div>';
    expect(issuableInitialDataById('test-element')).toBeNull();
  });

  it('returns parsed JSON data when valid data is present', () => {
    const testData = { foo: 'bar' };
    document.body.innerHTML = `<div id="test-element" data-initial='${JSON.stringify(testData)}'></div>`;
    expect(issuableInitialDataById('test-element')).toEqual(testData);
  });

  it('returns null when JSON parsing fails', () => {
    document.body.innerHTML = '<div id="test-element" data-initial="invalid-json"></div>';
    expect(issuableInitialDataById('test-element')).toBeNull();
  });
});

describe('isLegacyIssueType', () => {
  it('returns true for incident type', () => {
    const incidentData = { issueType: 'incident' };
    expect(isLegacyIssueType(incidentData)).toBe(true);
  });

  it('returns true for service desk issue', () => {
    const serviceDeskData = {
      issueType: 'issue',
      authorUsername: 'support-bot',
    };
    expect(isLegacyIssueType(serviceDeskData)).toBe(true);
  });

  it('returns false for regular issue', () => {
    const regularIssueData = {
      issueType: 'issue',
      authorUsername: 'regular-user',
    };
    expect(isLegacyIssueType(regularIssueData)).toBe(false);
  });

  it('returns false for undefined data', () => {
    expect(isLegacyIssueType(undefined)).toBe(false);
  });

  it('returns false for null data', () => {
    expect(isLegacyIssueType(null)).toBe(false);
  });

  it('returns false for empty object', () => {
    expect(isLegacyIssueType({})).toBe(false);
  });

  it('returns false when only issueType is present', () => {
    expect(isLegacyIssueType({ issueType: 'issue' })).toBe(false);
  });

  it('returns false when only authorUsername is present', () => {
    expect(isLegacyIssueType({ authorUsername: 'support-bot' })).toBe(false);
  });
});
