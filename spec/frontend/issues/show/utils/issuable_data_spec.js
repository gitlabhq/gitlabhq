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
    const incidentData = { isIncidentManagement: true };
    expect(isLegacyIssueType(incidentData)).toBe(true);
  });

  it('returns true for service desk issue', () => {
    const serviceDeskData = { isServiceDesk: true };
    expect(isLegacyIssueType(serviceDeskData)).toBe(true);
  });

  it('returns false when both false', () => {
    const regularIssueData = {
      isIncidentManagement: false,
      isServiceDesk: false,
    };
    expect(isLegacyIssueType(regularIssueData)).toBe(false);
  });

  it('returns undefined when non-existent', () => {
    const regularIssueData = {};
    expect(isLegacyIssueType(regularIssueData)).toBe(undefined);
  });
});
