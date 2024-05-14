import { GlLoadingIcon, GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { merge, last } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import tags from 'test_fixtures/api/tags/tags.json';
import commit from 'test_fixtures/api/commits/commit.json';
import branches from 'test_fixtures/api/branches/branches.json';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { trimText } from 'helpers/text_helper';
import {
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_NOT_FOUND,
  HTTP_STATUS_OK,
} from '~/lib/utils/http_status';
import { sprintf } from '~/locale';
import RefSelector from '~/ref/components/ref_selector.vue';
import {
  X_TOTAL_HEADER,
  DEFAULT_I18N,
  REF_TYPE_BRANCHES,
  REF_TYPE_TAGS,
  REF_TYPE_COMMITS,
  BRANCH_REF_TYPE_ICON,
  TAG_REF_TYPE_ICON,
} from '~/ref/constants';
import createStore from '~/ref/stores/';

Vue.use(Vuex);

describe('Ref selector component', () => {
  const branchRefTypeMock = { name: 'refs/heads/test_branch' };
  const tagRefTypeMock = { name: 'refs/tags/test_tag' };
  const protectedBranchMock = { name: 'protected_mock_branch', protected: true };
  const protectedTagMock = { name: 'protected_tag_mock', protected: true };
  const fixtures = {
    branches: [branchRefTypeMock, tagRefTypeMock, protectedBranchMock, ...branches],
    tags: [protectedTagMock, ...tags],
    commit,
  };

  const projectId = '8';
  const totalBranchesCount = 123;
  const totalTagsCount = 456;
  const queryParams = { sort: 'updated_desc' };

  let wrapper;
  let branchesApiCallSpy;
  let tagsApiCallSpy;
  let commitApiCallSpy;
  let requestSpies;

  const createComponent = ({ overrides = {}, propsData = {} } = {}) => {
    wrapper = mountExtended(
      RefSelector,
      merge(
        {
          propsData: {
            projectId,
            value: '',
            ...propsData,
          },
          listeners: {
            // simulate a parent component v-model binding
            input: (selectedRef) => {
              wrapper.setProps({ value: selectedRef });
            },
          },
          store: createStore(),
        },
        overrides,
      ),
    );
  };

  beforeEach(() => {
    const mock = new MockAdapter(axios);
    gon.api_version = 'v4';

    branchesApiCallSpy = jest
      .fn()
      .mockReturnValue([
        HTTP_STATUS_OK,
        fixtures.branches,
        { [X_TOTAL_HEADER]: totalBranchesCount },
      ]);
    tagsApiCallSpy = jest
      .fn()
      .mockReturnValue([HTTP_STATUS_OK, fixtures.tags, { [X_TOTAL_HEADER]: totalTagsCount }]);
    commitApiCallSpy = jest.fn().mockReturnValue([HTTP_STATUS_OK, fixtures.commit]);
    requestSpies = { branchesApiCallSpy, tagsApiCallSpy, commitApiCallSpy };

    mock
      .onGet(`/api/v4/projects/${projectId}/repository/branches`)
      .reply((config) => branchesApiCallSpy(config));
    mock
      .onGet(`/api/v4/projects/${projectId}/repository/tags`)
      .reply((config) => tagsApiCallSpy(config));
    mock
      .onGet(new RegExp(`/api/v4/projects/${projectId}/repository/commits/.*`))
      .reply((config) => commitApiCallSpy(config));
  });

  //
  // Finders
  //
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);

  const findButtonToggle = () => wrapper.findByTestId('base-dropdown-toggle');

  const findNoResults = () => wrapper.findByTestId('listbox-no-results-text');

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const findListBoxSection = (section) => {
    const foundSections = wrapper
      .findAll('[role="group"]')
      .filter((ul) => ul.text().includes(section));
    return foundSections.length > 0 ? foundSections.at(0) : foundSections;
  };

  const findErrorListWrapper = () => wrapper.findByTestId('red-selector-error-list');

  const findBranchesSection = () => findListBoxSection('Branches');
  const findBranchDropdownItems = () => wrapper.findAllComponents(GlListboxItem);

  const findTagsSection = () => findListBoxSection('Tags');

  const findCommitsSection = () => findListBoxSection('Commits');

  const findHiddenInputField = () => wrapper.findByTestId('selected-ref-form-field');

  //
  // Expecters
  //
  const sectionContainsErrorMessage = (message) => {
    const errorSection = findErrorListWrapper();

    return errorSection ? errorSection.text().includes(message) : false;
  };

  //
  // Convenience methods
  //
  const updateQuery = (newQuery) => {
    findListbox().vm.$emit('search', newQuery);
  };

  const selectFirstBranch = async () => {
    findListbox().vm.$emit('select', fixtures.branches[0].name);
    await nextTick();
  };

  const selectFirstTag = async () => {
    findListbox().vm.$emit('select', fixtures.tags[0].name);
    await nextTick();
  };

  const selectFirstCommit = async () => {
    findListbox().vm.$emit('select', fixtures.commit.id);
    await nextTick();
  };

  const waitForRequests = ({ andClearMocks } = { andClearMocks: false }) =>
    axios.waitForAll().then(() => {
      if (andClearMocks) {
        branchesApiCallSpy.mockClear();
        tagsApiCallSpy.mockClear();
        commitApiCallSpy.mockClear();
      }
    });

  describe('initialization behavior', () => {
    it('initializes the dropdown with branches and tags when mounted', () => {
      createComponent();

      return waitForRequests().then(() => {
        expect(branchesApiCallSpy).toHaveBeenCalledTimes(1);
        expect(tagsApiCallSpy).toHaveBeenCalledTimes(1);
        expect(commitApiCallSpy).not.toHaveBeenCalled();
      });
    });

    it('shows a spinner while network requests are in progress', () => {
      createComponent();

      expect(findLoadingIcon().exists()).toBe(true);

      return waitForRequests().then(() => {
        expect(findLoadingIcon().exists()).toBe(false);
      });
    });

    describe('when name property is provided', () => {
      it('renders an form input hidden field', () => {
        const name = 'default_tag';

        createComponent({ propsData: { name } });

        expect(findHiddenInputField().attributes().name).toBe(name);
      });
    });

    describe('when name property is not provided', () => {
      it('renders an form input hidden field', () => {
        createComponent();

        expect(findHiddenInputField().exists()).toBe(false);
      });
    });
  });

  describe('post-initialization behavior', () => {
    describe('when the parent component provides an `id` binding', () => {
      const id = 'git-ref';

      beforeEach(() => {
        createComponent({ overrides: { attrs: { id } } });

        return waitForRequests();
      });

      it('adds the provided ID to the GlDropdown instance', () => {
        expect(findListbox().attributes().id).toBe(id);
      });
    });

    describe('when a ref is pre-selected', () => {
      const preselectedRef = fixtures.branches[0].name;

      beforeEach(() => {
        createComponent({ propsData: { value: preselectedRef, name: 'selectedRef' } });

        return waitForRequests();
      });

      it('renders the pre-selected ref name', () => {
        expect(findButtonToggle().text()).toBe(preselectedRef);
      });

      it('binds hidden input field to the pre-selected ref', () => {
        expect(findHiddenInputField().attributes().value).toBe(preselectedRef);
      });
    });

    describe('when the selected ref is updated by the parent component', () => {
      const updatedRef = fixtures.branches[0].name;

      beforeEach(() => {
        createComponent();

        return waitForRequests();
      });

      it('renders the updated ref name', async () => {
        wrapper.setProps({ value: updatedRef });

        await nextTick();
        expect(findButtonToggle().text()).toBe(updatedRef);
      });
    });

    describe('when the search query is updated', () => {
      beforeEach(() => {
        createComponent();

        return waitForRequests({ andClearMocks: true });
      });

      it('requeries the endpoints when the search query is updated', () => {
        updateQuery('v1.2.3');

        return waitForRequests().then(() => {
          expect(branchesApiCallSpy).toHaveBeenCalledTimes(1);
          expect(tagsApiCallSpy).toHaveBeenCalledTimes(1);
        });
      });

      it("does not make a call to the commit endpoint if the query doesn't look like a SHA", () => {
        updateQuery('not a sha');

        return waitForRequests().then(() => {
          expect(commitApiCallSpy).not.toHaveBeenCalled();
        });
      });

      it('searches for a commit if the query could potentially be a SHA', () => {
        updateQuery('abcdef');

        return waitForRequests().then(() => {
          expect(commitApiCallSpy).toHaveBeenCalled();
        });
      });
    });

    describe('when no results are found', () => {
      beforeEach(() => {
        branchesApiCallSpy = jest
          .fn()
          .mockReturnValue([HTTP_STATUS_OK, [], { [X_TOTAL_HEADER]: '0' }]);
        tagsApiCallSpy = jest.fn().mockReturnValue([HTTP_STATUS_OK, [], { [X_TOTAL_HEADER]: '0' }]);
        commitApiCallSpy = jest.fn().mockReturnValue([HTTP_STATUS_NOT_FOUND]);

        createComponent();

        return waitForRequests();
      });

      describe('when the search query is empty', () => {
        it('renders a "no results" message', () => {
          expect(findNoResults().text()).toBe(DEFAULT_I18N.noResults);
        });
      });

      describe('when the search query is not empty', () => {
        const query = 'hello';

        beforeEach(() => {
          updateQuery(query);

          return waitForRequests();
        });

        it('renders a "no results" message that includes the search query', () => {
          expect(findNoResults().text()).toBe(sprintf(DEFAULT_I18N.noResultsWithQuery, { query }));
        });
      });
    });

    describe('branches', () => {
      describe('when the branches search returns results', () => {
        beforeEach(() => {
          createComponent({ propsData: { useSymbolicRefNames: true } });

          return waitForRequests();
        });

        it('renders the branches section in the dropdown', () => {
          expect(findBranchesSection().exists()).toBe(true);
        });

        it("does not render an error message in the branches section's body", () => {
          expect(findErrorListWrapper().exists()).toBe(false);
        });

        it('renders the default branch as a selectable item with a "default" badge', () => {
          const dropdownItems = findBranchDropdownItems();

          const defaultBranch = fixtures.branches.find((b) => b.default);
          const defaultBranchIndex = fixtures.branches.indexOf(defaultBranch);

          expect(trimText(dropdownItems.at(defaultBranchIndex).text())).toBe(
            `${defaultBranch.name} default`,
          );
        });

        it('renders the protected branch as a selectable item with a "protected" badge', () => {
          const dropdownItems = findBranchDropdownItems();
          const protectedBranch = fixtures.branches.find((b) => b.protected);
          const protectedBranchIndex = fixtures.branches.indexOf(protectedBranch);

          expect(trimText(dropdownItems.at(protectedBranchIndex).text())).toBe(
            `${protectedBranch.name} protected`,
          );
        });
      });

      describe('when the branches search returns no results', () => {
        beforeEach(() => {
          branchesApiCallSpy = jest
            .fn()
            .mockReturnValue([HTTP_STATUS_OK, [], { [X_TOTAL_HEADER]: '0' }]);

          createComponent();

          return waitForRequests();
        });

        it('does not render the branches section in the dropdown', () => {
          expect(findBranchesSection().exists()).toBe(false);
        });
      });

      describe('when the branches search returns an error', () => {
        beforeEach(() => {
          branchesApiCallSpy = jest.fn().mockReturnValue([HTTP_STATUS_INTERNAL_SERVER_ERROR]);

          createComponent();

          return waitForRequests();
        });

        it('renders the branches section in the dropdown', () => {
          expect(findBranchesSection().exists()).toBe(false);
        });

        it("renders an error message in the branches section's body", () => {
          expect(sectionContainsErrorMessage(DEFAULT_I18N.branchesErrorMessage)).toBe(true);
        });
      });
    });

    describe('tags', () => {
      describe('when the tags search returns results', () => {
        beforeEach(() => {
          createComponent({ propsData: { useSymbolicRefNames: true } });

          return waitForRequests();
        });

        it('renders the tags section in the dropdown', () => {
          expect(findTagsSection().exists()).toBe(true);
        });

        it('renders the "Tags" heading with a total number indicator', () => {
          expect(findTagsSection().find('[role="presentation"]').text()).toMatchInterpolatedText(
            `Tags ${fixtures.tags.length}`,
          );
        });

        it("does not render an error message in the tags section's body", () => {
          expect(findErrorListWrapper().exists()).toBe(false);
        });

        it('renders the protected tag as a selectable item with a "protected" badge', () => {
          const dropdownItems = findBranchDropdownItems();
          const protectedTag = fixtures.tags.find((b) => b.protected);
          const protectedTagIndex = fixtures.tags.indexOf(protectedTag) + fixtures.branches.length;

          expect(trimText(dropdownItems.at(protectedTagIndex).text())).toBe(
            `${protectedTag.name} protected`,
          );
        });
      });

      describe('when the tags search returns no results', () => {
        beforeEach(() => {
          tagsApiCallSpy = jest
            .fn()
            .mockReturnValue([HTTP_STATUS_OK, [], { [X_TOTAL_HEADER]: '0' }]);

          createComponent();

          return waitForRequests();
        });

        it('does not render the tags section in the dropdown', () => {
          expect(findTagsSection().exists()).toBe(false);
        });
      });

      describe('when the tags search returns an error', () => {
        beforeEach(() => {
          tagsApiCallSpy = jest.fn().mockReturnValue([HTTP_STATUS_INTERNAL_SERVER_ERROR]);

          createComponent();

          return waitForRequests();
        });

        it('renders the tags section in the dropdown', () => {
          expect(findTagsSection().exists()).toBe(false);
        });

        it("renders an error message in the tags section's body", () => {
          expect(sectionContainsErrorMessage(DEFAULT_I18N.tagsErrorMessage)).toBe(true);
        });
      });
    });

    describe('commits', () => {
      describe('when the commit search returns results', () => {
        beforeEach(() => {
          createComponent();

          updateQuery('abcd1234');

          return waitForRequests();
        });

        it('renders the commit section in the dropdown', () => {
          expect(findCommitsSection().exists()).toBe(true);
        });

        it('renders the "Commits" heading with a total number indicator', () => {
          expect(findCommitsSection().find('[role="presentation"]').text()).toMatchInterpolatedText(
            `Commits 1`,
          );
        });

        it("does not render an error message in the commits section's body", () => {
          expect(findErrorListWrapper().exists()).toBe(false);
        });
      });

      describe('when the commit search returns no results (i.e. a 404)', () => {
        beforeEach(() => {
          commitApiCallSpy = jest.fn().mockReturnValue([HTTP_STATUS_NOT_FOUND]);

          createComponent();

          updateQuery('abcd1234');

          return waitForRequests();
        });

        it('does not render the commits section in the dropdown', () => {
          expect(findCommitsSection().exists()).toBe(false);
        });
      });

      describe('when the commit search returns an error (other than a 404)', () => {
        beforeEach(() => {
          commitApiCallSpy = jest.fn().mockReturnValue([HTTP_STATUS_INTERNAL_SERVER_ERROR]);

          createComponent();

          updateQuery('abcd1234');

          return waitForRequests();
        });

        it('renders the commits section in the dropdown', () => {
          expect(findCommitsSection().exists()).toBe(false);
        });

        it("renders an error message in the commits section's body", () => {
          expect(sectionContainsErrorMessage(DEFAULT_I18N.commitsErrorMessage)).toBe(true);
        });
      });
    });

    describe('selection', () => {
      beforeEach(() => {
        createComponent();

        updateQuery(fixtures.commit.short_id);

        return waitForRequests();
      });

      describe('when a branch is selected', () => {
        it("displays the branch name in the dropdown's button", async () => {
          expect(findButtonToggle().text()).toBe(DEFAULT_I18N.noRefSelected);

          await selectFirstBranch();

          expect(findButtonToggle().text()).toBe(fixtures.branches[0].name);
        });

        it("updates the v-model binding with the branch's name", async () => {
          expect(findListbox().props('selected')).toBe('');

          await selectFirstBranch();

          expect(findListbox().props('selected')).toBe(fixtures.branches[0].name);
        });
      });

      describe('when a tag is seleceted', () => {
        it("displays the tag name in the dropdown's button", async () => {
          expect(findButtonToggle().text()).toBe(DEFAULT_I18N.noRefSelected);

          await selectFirstTag();

          expect(findButtonToggle().text()).toBe(fixtures.tags[0].name);
        });

        it("updates the v-model binding with the tag's name", async () => {
          expect(findListbox().props('selected')).toBe('');

          await selectFirstTag();

          expect(findListbox().props('selected')).toBe(fixtures.tags[0].name);
        });
      });

      describe('when a commit is selected', () => {
        it("displays the full SHA in the dropdown's button", async () => {
          expect(findButtonToggle().text()).toBe(DEFAULT_I18N.noRefSelected);

          await selectFirstCommit();

          expect(findButtonToggle().text()).toBe(fixtures.commit.id);
        });

        it("updates the v-model binding with the commit's full SHA", async () => {
          expect(findListbox().props('selected')).toBe('');

          await selectFirstCommit();

          expect(findListbox().props('selected')).toBe(fixtures.commit.id);
        });
      });
    });

    describe('disabled', () => {
      it('does not disable the dropdown', () => {
        createComponent();
        expect(findListbox().props('disabled')).toBe(false);
      });

      it('disables the dropdown', async () => {
        createComponent({ propsData: { disabled: true } });
        expect(findListbox().props('disabled')).toBe(true);
        await selectFirstBranch();
        expect(wrapper.emitted('input')).toBeUndefined();
      });
    });
  });

  describe('with non-default ref types', () => {
    it.each`
      enabledRefTypes                      | reqsCalled                | reqsNotCalled
      ${[REF_TYPE_BRANCHES]}               | ${['branchesApiCallSpy']} | ${['tagsApiCallSpy', 'commitApiCallSpy']}
      ${[REF_TYPE_TAGS]}                   | ${['tagsApiCallSpy']}     | ${['branchesApiCallSpy', 'commitApiCallSpy']}
      ${[REF_TYPE_COMMITS]}                | ${[]}                     | ${['branchesApiCallSpy', 'tagsApiCallSpy', 'commitApiCallSpy']}
      ${[REF_TYPE_TAGS, REF_TYPE_COMMITS]} | ${['tagsApiCallSpy']}     | ${['branchesApiCallSpy', 'commitApiCallSpy']}
    `(
      'only calls $reqsCalled requests when $enabledRefTypes are enabled',
      async ({ enabledRefTypes, reqsCalled, reqsNotCalled }) => {
        createComponent({ propsData: { enabledRefTypes } });

        await waitForRequests();

        reqsCalled.forEach((req) => expect(requestSpies[req]).toHaveBeenCalledTimes(1));
        reqsNotCalled.forEach((req) => expect(requestSpies[req]).not.toHaveBeenCalled());
      },
    );

    it('only calls commitApiCallSpy when REF_TYPE_COMMITS is enabled', async () => {
      createComponent({ propsData: { enabledRefTypes: [REF_TYPE_COMMITS] } });
      updateQuery('abcd1234');

      await waitForRequests();

      expect(commitApiCallSpy).toHaveBeenCalledTimes(1);
      expect(branchesApiCallSpy).not.toHaveBeenCalled();
      expect(tagsApiCallSpy).not.toHaveBeenCalled();
    });

    it('triggers another search if enabled ref types change', async () => {
      createComponent({ propsData: { enabledRefTypes: [REF_TYPE_BRANCHES] } });
      await waitForRequests();

      expect(branchesApiCallSpy).toHaveBeenCalledTimes(1);
      expect(tagsApiCallSpy).not.toHaveBeenCalled();

      wrapper.setProps({
        enabledRefTypes: [REF_TYPE_BRANCHES, REF_TYPE_TAGS],
      });
      await waitForRequests();

      expect(branchesApiCallSpy).toHaveBeenCalledTimes(2);
      expect(tagsApiCallSpy).toHaveBeenCalledTimes(1);
    });

    it.each`
      selectedBranch            | icon
      ${branchRefTypeMock.name} | ${BRANCH_REF_TYPE_ICON}
      ${tagRefTypeMock.name}    | ${TAG_REF_TYPE_ICON}
      ${branches[0].name}       | ${''}
    `('renders the correct icon for the selected ref', async ({ selectedBranch, icon }) => {
      createComponent();
      findListbox().vm.$emit('select', selectedBranch);
      await nextTick();

      expect(findListbox().props('icon')).toBe(icon);
    });

    it.each`
      enabledRefType       | findVisibleSection     | findHiddenSections
      ${REF_TYPE_BRANCHES} | ${findBranchesSection} | ${[findTagsSection, findCommitsSection]}
      ${REF_TYPE_TAGS}     | ${findTagsSection}     | ${[findBranchesSection, findCommitsSection]}
      ${REF_TYPE_COMMITS}  | ${findCommitsSection}  | ${[findBranchesSection, findTagsSection]}
    `(
      'hides section headers if a single ref type is enabled',
      async ({ enabledRefType, findVisibleSection, findHiddenSections }) => {
        createComponent({ propsData: { enabledRefTypes: [enabledRefType] } });
        updateQuery('abcd1234');
        await waitForRequests();

        expect(findVisibleSection().exists()).toBe(true);
        expect(findVisibleSection().find('[data-testid="section-header"]').exists()).toBe(false);
        findHiddenSections.forEach((findHiddenSection) =>
          expect(findHiddenSection().exists()).toBe(false),
        );
      },
    );
  });

  describe('validation state', () => {
    const invalidClass = '!gl-shadow-inner-1-red-500';
    const isInvalidClassApplied = () => findListbox().props('toggleClass')[0][invalidClass];

    describe('valid state', () => {
      describe('when the state prop is not provided', () => {
        it('does not render a red border', () => {
          createComponent();

          expect(isInvalidClassApplied()).toBe(false);
        });
      });

      describe('when the state prop is true', () => {
        it('does not render a red border', () => {
          createComponent({ propsData: { state: true } });

          expect(isInvalidClassApplied()).toBe(false);
        });
      });
    });

    describe('invalid state', () => {
      it('renders the dropdown with a red border if the state prop is false', () => {
        createComponent({ propsData: { state: false } });

        expect(isInvalidClassApplied()).toBe(true);
      });
    });
  });

  describe('footer slot', () => {
    const footerContent = 'This is the footer content';
    const createFooter = jest.fn().mockImplementation(function createMockFooter() {
      return this.$createElement('div', { attrs: { 'data-testid': 'footer-content' } }, [
        footerContent,
      ]);
    });

    beforeEach(() => {
      createComponent({ overrides: { scopedSlots: { footer: createFooter } } });

      updateQuery('abcd1234');

      return waitForRequests();
    });

    afterEach(() => {
      createFooter.mockClear();
    });

    it('allows custom content to be shown at the bottom of the dropdown using the footer slot', () => {
      expect(wrapper.find(`[data-testid="footer-content"]`).text()).toBe(footerContent);
    });

    it('passes the expected slot props', () => {
      // The createFooter function gets called every time one of the scoped properties
      // is updated. For the sake of this test, we'll just test the last call, which
      // represents the final state of the slot props.
      const lastCallProps = last(createFooter.mock.calls)[0];
      expect(lastCallProps.isLoading).toBe(false);
      expect(lastCallProps.query).toBe('abcd1234');

      const branchesList = fixtures.branches.map((branch) => {
        return {
          default: branch.default,
          name: branch.name,
        };
      });

      const commitsList = [
        {
          name: fixtures.commit.short_id,
          subtitle: fixtures.commit.title,
          value: fixtures.commit.id,
        },
      ];

      const tagsList = fixtures.tags.map((tag) => {
        return {
          name: tag.name,
        };
      });

      const expectedMatches = {
        branches: {
          list: branchesList,
          totalCount: totalBranchesCount,
        },
        commits: {
          list: commitsList,
          totalCount: 1,
        },
        tags: {
          list: tagsList,
          totalCount: totalTagsCount,
        },
      };

      expect(lastCallProps.matches).toMatchObject(expectedMatches);
    });
  });
  describe('when queryParam prop is present', () => {
    it('passes params to a branches API call', () => {
      createComponent({ propsData: { queryParams } });

      return waitForRequests().then(() => {
        expect(branchesApiCallSpy).toHaveBeenCalledWith(
          expect.objectContaining({ params: { per_page: 20, search: '', sort: queryParams.sort } }),
        );
      });
    });

    it('does not pass params to tags API call', () => {
      createComponent({ propsData: { queryParams } });

      return waitForRequests().then(() => {
        expect(tagsApiCallSpy).toHaveBeenCalledWith(
          expect.objectContaining({ params: { per_page: 20, search: '' } }),
        );
      });
    });
  });
});
