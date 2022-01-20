import createState from '~/integrations/edit/store/state';

describe('Integration form state factory', () => {
  it('states default to null', () => {
    expect(createState()).toEqual({
      defaultState: null,
      customState: {},
      override: false,
      isLoadingJiraIssueTypes: false,
      jiraIssueTypes: [],
      loadingJiraIssueTypesErrorMessage: '',
    });
  });

  describe('override is initialized correctly', () => {
    it.each([
      [{ id: 25 }, { inheritFromId: null }, true],
      [{ id: 25 }, { inheritFromId: 27 }, true],
      [{ id: 25 }, { inheritFromId: 25 }, false],
      [null, { inheritFromId: null }, false],
      [null, { inheritFromId: 25 }, false],
    ])(
      'for defaultState: %p, customState: %p: override = `%p`',
      (defaultState, customState, expected) => {
        expect(createState({ defaultState, customState }).override).toEqual(expected);
      },
    );
  });
});
