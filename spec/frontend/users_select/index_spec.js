import {
  createInputsModelExpectation,
  createUnassignedExpectation,
  createAssignedExpectation,
  createTestContext,
  findDropdownItemsModel,
  findDropdownItem,
  findAssigneesInputsModel,
  getUsersFixtureAt,
  setAssignees,
  toggleDropdown,
  waitForDropdownItems,
} from './test_helper';

describe('~/users_select/index', () => {
  const context = createTestContext({
    fixturePath: 'merge_requests/merge_request_with_single_assignee_feature.html',
  });

  beforeEach(() => {
    context.setup();
  });

  afterEach(() => {
    context.teardown();
  });

  describe('when opened', () => {
    beforeEach(async () => {
      context.createSubject();

      toggleDropdown();
      await waitForDropdownItems();
    });

    it('shows users', () => {
      expect(findDropdownItemsModel()).toEqual(createUnassignedExpectation());
    });

    describe('when users are selected', () => {
      const selectedUsers = [getUsersFixtureAt(2), getUsersFixtureAt(4)];
      const lastSelected = selectedUsers[selectedUsers.length - 1];
      const expectation = createAssignedExpectation({
        header: 'Assignee',
        assigned: [lastSelected],
      });

      beforeEach(() => {
        selectedUsers.forEach((user) => {
          findDropdownItem(user).click();
        });
      });

      it('shows assignee', () => {
        expect(findDropdownItemsModel()).toEqual(expectation);
      });

      it('updates field', () => {
        expect(findAssigneesInputsModel()).toEqual(createInputsModelExpectation([lastSelected]));
      });
    });
  });

  describe('with preselected user and opened', () => {
    const expectation = createAssignedExpectation({
      header: 'Assignee',
      assigned: [getUsersFixtureAt(0)],
    });

    beforeEach(async () => {
      setAssignees(getUsersFixtureAt(0));

      context.createSubject();

      toggleDropdown();
      await waitForDropdownItems();
    });

    it('shows users', () => {
      expect(findDropdownItemsModel()).toEqual(expectation);
    });

    // Regression test for https://gitlab.com/gitlab-org/gitlab/-/issues/325991
    describe('when closed and reopened', () => {
      beforeEach(() => {
        toggleDropdown();
        toggleDropdown();
      });

      it('shows users', () => {
        expect(findDropdownItemsModel()).toEqual(expectation);
      });
    });
  });
});
