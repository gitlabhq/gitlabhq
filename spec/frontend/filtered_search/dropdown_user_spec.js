import DropdownUtils from '~/filtered_search/dropdown_utils';
// TODO: Moving this line up throws an error about `FilteredSearchDropdown`
// being undefined in test. See gitlab-org/gitlab#321476 for more info.
// eslint-disable-next-line import/order
import DropdownUser from '~/filtered_search/dropdown_user';
import FilteredSearchTokenizer from '~/filtered_search/filtered_search_tokenizer';
import IssuableFilteredTokenKeys from '~/filtered_search/issuable_filtered_search_token_keys';

describe('Dropdown User', () => {
  describe('getSearchInput', () => {
    let dropdownUser;

    beforeEach(() => {
      jest.spyOn(DropdownUser.prototype, 'bindEvents').mockImplementation(() => {});
      jest.spyOn(DropdownUser.prototype, 'getProjectId').mockImplementation(() => {});
      jest.spyOn(DropdownUser.prototype, 'getGroupId').mockImplementation(() => {});
      jest.spyOn(DropdownUtils, 'getSearchInput').mockImplementation(() => {});

      dropdownUser = new DropdownUser({
        tokenKeys: IssuableFilteredTokenKeys,
      });
    });

    it('should not return the double quote found in value', () => {
      jest.spyOn(FilteredSearchTokenizer, 'processTokens').mockReturnValue({
        lastToken: '"johnny appleseed',
      });

      expect(dropdownUser.getSearchInput()).toBe('johnny appleseed');
    });

    it('should not return the single quote found in value', () => {
      jest.spyOn(FilteredSearchTokenizer, 'processTokens').mockReturnValue({
        lastToken: "'larry boy",
      });

      expect(dropdownUser.getSearchInput()).toBe('larry boy');
    });
  });

  describe("config AjaxFilter's endpoint", () => {
    beforeEach(() => {
      jest.spyOn(DropdownUser.prototype, 'bindEvents').mockImplementation(() => {});
      jest.spyOn(DropdownUser.prototype, 'getProjectId').mockImplementation(() => {});
      jest.spyOn(DropdownUser.prototype, 'getGroupId').mockImplementation(() => {});
    });

    it('should return endpoint', () => {
      window.gon = {
        relative_url_root: '',
      };
      const dropdown = new DropdownUser();

      expect(dropdown.config.AjaxFilter.endpoint).toBe('/-/autocomplete/users.json');
    });

    it('should return endpoint when relative_url_root is undefined', () => {
      const dropdown = new DropdownUser();

      expect(dropdown.config.AjaxFilter.endpoint).toBe('/-/autocomplete/users.json');
    });

    it('should return endpoint with relative url when available', () => {
      window.gon = {
        relative_url_root: '/gitlab_directory',
      };
      const dropdown = new DropdownUser();

      expect(dropdown.config.AjaxFilter.endpoint).toBe(
        '/gitlab_directory/-/autocomplete/users.json',
      );
    });

    afterEach(() => {
      window.gon = {};
    });
  });

  describe('hideCurrentUser', () => {
    const fixtureTemplate = 'issues/issue_list.html';

    let dropdown;
    let authorFilterDropdownElement;

    beforeEach(() => {
      loadFixtures(fixtureTemplate);
      authorFilterDropdownElement = document.querySelector('#js-dropdown-author');
      const dummyInput = document.createElement('div');
      dropdown = new DropdownUser({
        dropdown: authorFilterDropdownElement,
        input: dummyInput,
      });
    });

    const findCurrentUserElement = () =>
      authorFilterDropdownElement.querySelector('.js-current-user');

    it('hides the current user from dropdown', () => {
      const currentUserElement = findCurrentUserElement();

      expect(currentUserElement).not.toBe(null);

      dropdown.hideCurrentUser();

      expect(currentUserElement.classList).toContain('hidden');
    });

    it('does nothing if no user is logged in', () => {
      const currentUserElement = findCurrentUserElement();
      currentUserElement.parentNode.removeChild(currentUserElement);

      expect(findCurrentUserElement()).toBe(null);

      dropdown.hideCurrentUser();
    });
  });
});
