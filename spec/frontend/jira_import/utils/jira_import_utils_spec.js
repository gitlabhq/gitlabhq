import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { JIRA_IMPORT_SUCCESS_ALERT_HIDE_MAP_KEY } from '~/jira_import/utils/constants';
import {
  calculateJiraImportLabel,
  extractJiraProjectsOptions,
  IMPORT_STATE,
  isFinished,
  isInProgress,
  setFinishedAlertHideMap,
  shouldShowFinishedAlert,
} from '~/jira_import/utils/jira_import_utils';

useLocalStorageSpy();

describe('isInProgress', () => {
  it.each`
    state                     | result
    ${IMPORT_STATE.SCHEDULED} | ${true}
    ${IMPORT_STATE.STARTED}   | ${true}
    ${IMPORT_STATE.FAILED}    | ${false}
    ${IMPORT_STATE.FINISHED}  | ${false}
    ${IMPORT_STATE.NONE}      | ${false}
    ${undefined}              | ${false}
  `('returns $result when state is $state', ({ state, result }) => {
    expect(isInProgress(state)).toBe(result);
  });
});

describe('isFinished', () => {
  it.each`
    state                     | result
    ${IMPORT_STATE.SCHEDULED} | ${false}
    ${IMPORT_STATE.STARTED}   | ${false}
    ${IMPORT_STATE.FAILED}    | ${false}
    ${IMPORT_STATE.FINISHED}  | ${true}
    ${IMPORT_STATE.NONE}      | ${false}
    ${undefined}              | ${false}
  `('returns $result when state is $state', ({ state, result }) => {
    expect(isFinished(state)).toBe(result);
  });
});

describe('extractJiraProjectsOptions', () => {
  const jiraProjects = [
    {
      key: 'MJP',
      name: 'My Jira project',
    },
    {
      key: 'MTG',
      name: 'Migrate to GitLab',
    },
  ];

  const expected = [
    {
      text: 'My Jira project (MJP)',
      value: 'MJP',
    },
    {
      text: 'Migrate to GitLab (MTG)',
      value: 'MTG',
    },
  ];

  it('returns a list of Jira projects in a format suitable for GlFormSelect', () => {
    expect(extractJiraProjectsOptions(jiraProjects)).toEqual(expected);
  });
});

describe('calculateJiraImportLabel', () => {
  const jiraImports = [
    { jiraProjectKey: 'MTG' },
    { jiraProjectKey: 'MJP' },
    { jiraProjectKey: 'MTG' },
    { jiraProjectKey: 'MSJP' },
    { jiraProjectKey: 'MTG' },
  ];

  const labels = [
    { color: '#111', title: 'jira-import::MTG-1' },
    { color: '#222', title: 'jira-import::MTG-2' },
    { color: '#333', title: 'jira-import::MTG-3' },
  ];

  it('returns a label with the Jira project key and correct import count in the title', () => {
    const label = calculateJiraImportLabel(jiraImports, labels);

    expect(label.title).toBe('jira-import::MTG-3');
  });

  it('returns a label with the correct color', () => {
    const label = calculateJiraImportLabel(jiraImports, labels);

    expect(label.color).toBe('#333');
  });
});

describe('shouldShowFinishedAlert', () => {
  const labelTitle = 'jira-import::JCP-1';

  afterEach(() => {
    localStorage.clear();
  });

  it('checks localStorage value', () => {
    jest.spyOn(localStorage, 'getItem').mockReturnValue(JSON.stringify({}));

    shouldShowFinishedAlert(labelTitle, IMPORT_STATE.FINISHED);

    expect(localStorage.getItem).toHaveBeenCalledWith(JIRA_IMPORT_SUCCESS_ALERT_HIDE_MAP_KEY);
  });

  it('returns true when an import has finished', () => {
    jest.spyOn(localStorage, 'getItem').mockReturnValue(JSON.stringify({}));

    expect(shouldShowFinishedAlert(labelTitle, IMPORT_STATE.FINISHED)).toBe(true);
  });

  it('returns false when an import has finished but the user chose to hide the alert', () => {
    jest.spyOn(localStorage, 'getItem').mockReturnValue(JSON.stringify({ [labelTitle]: true }));

    expect(shouldShowFinishedAlert(labelTitle, IMPORT_STATE.FINISHED)).toBe(false);
  });

  it('returns false when an import has not finished', () => {
    jest.spyOn(localStorage, 'getItem').mockReturnValue(JSON.stringify({}));

    expect(shouldShowFinishedAlert(labelTitle, IMPORT_STATE.SCHEDULED)).toBe(false);
  });
});

describe('setFinishedAlertHideMap', () => {
  const labelTitle = 'jira-import::ABC-1';
  const newLabelTitle = 'jira-import::JCP-1';

  it('sets item to localStorage correctly', () => {
    jest.spyOn(localStorage, 'getItem').mockReturnValue(JSON.stringify({ [labelTitle]: true }));

    setFinishedAlertHideMap(newLabelTitle);

    expect(localStorage.setItem).toHaveBeenCalledWith(
      JIRA_IMPORT_SUCCESS_ALERT_HIDE_MAP_KEY,
      JSON.stringify({
        [labelTitle]: true,
        [newLabelTitle]: true,
      }),
    );
  });
});
