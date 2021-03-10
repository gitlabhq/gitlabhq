import { GlLoadingIcon, GlSearchBoxByType, GlDropdownItem, GlDropdown, GlIcon } from '@gitlab/ui';
import { mount, createLocalVue } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { merge, last } from 'lodash';
import Vuex from 'vuex';
import { trimText } from 'helpers/text_helper';
import { ENTER_KEY } from '~/lib/utils/keys';
import { sprintf } from '~/locale';
import RefSelector from '~/ref/components/ref_selector.vue';
import {
  X_TOTAL_HEADER,
  DEFAULT_I18N,
  REF_TYPE_BRANCHES,
  REF_TYPE_TAGS,
  REF_TYPE_COMMITS,
} from '~/ref/constants';
import createStore from '~/ref/stores/';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Ref selector component', () => {
  const fixtures = {
    branches: getJSONFixture('api/branches/branches.json'),
    tags: getJSONFixture('api/tags/tags.json'),
    commit: getJSONFixture('api/commits/commit.json'),
  };

  const projectId = '8';

  let wrapper;
  let branchesApiCallSpy;
  let tagsApiCallSpy;
  let commitApiCallSpy;
  let requestSpies;

  const createComponent = (mountOverrides = {}) => {
    wrapper = mount(
      RefSelector,
      merge(
        {
          propsData: {
            projectId,
            value: '',
          },
          listeners: {
            // simulate a parent component v-model binding
            input: (selectedRef) => {
              wrapper.setProps({ value: selectedRef });
            },
          },
          stubs: {
            GlSearchBoxByType: true,
          },
          localVue,
          store: createStore(),
        },
        mountOverrides,
      ),
    );
  };

  beforeEach(() => {
    const mock = new MockAdapter(axios);
    gon.api_version = 'v4';

    branchesApiCallSpy = jest
      .fn()
      .mockReturnValue([200, fixtures.branches, { [X_TOTAL_HEADER]: '123' }]);
    tagsApiCallSpy = jest.fn().mockReturnValue([200, fixtures.tags, { [X_TOTAL_HEADER]: '456' }]);
    commitApiCallSpy = jest.fn().mockReturnValue([200, fixtures.commit]);
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

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  //
  // Finders
  //
  const findButtonContent = () => wrapper.find('button');

  const findNoResults = () => wrapper.find('[data-testid="no-results"]');

  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);

  const findSearchBox = () => wrapper.find(GlSearchBoxByType);

  const findBranchesSection = () => wrapper.find('[data-testid="branches-section"]');
  const findBranchDropdownItems = () => findBranchesSection().findAll(GlDropdownItem);
  const findFirstBranchDropdownItem = () => findBranchDropdownItems().at(0);

  const findTagsSection = () => wrapper.find('[data-testid="tags-section"]');
  const findTagDropdownItems = () => findTagsSection().findAll(GlDropdownItem);
  const findFirstTagDropdownItem = () => findTagDropdownItems().at(0);

  const findCommitsSection = () => wrapper.find('[data-testid="commits-section"]');
  const findCommitDropdownItems = () => findCommitsSection().findAll(GlDropdownItem);
  const findFirstCommitDropdownItem = () => findCommitDropdownItems().at(0);

  //
  // Expecters
  //
  const branchesSectionContainsErrorMessage = () => {
    const branchesSection = findBranchesSection();

    return branchesSection.text().includes(DEFAULT_I18N.branchesErrorMessage);
  };

  const tagsSectionContainsErrorMessage = () => {
    const tagsSection = findTagsSection();

    return tagsSection.text().includes(DEFAULT_I18N.tagsErrorMessage);
  };

  const commitsSectionContainsErrorMessage = () => {
    const commitsSection = findCommitsSection();

    return commitsSection.text().includes(DEFAULT_I18N.commitsErrorMessage);
  };

  //
  // Convenience methods
  //
  const updateQuery = (newQuery) => {
    findSearchBox().vm.$emit('input', newQuery);
  };

  const selectFirstBranch = () => {
    findFirstBranchDropdownItem().vm.$emit('click');
    return wrapper.vm.$nextTick();
  };

  const selectFirstTag = () => {
    findFirstTagDropdownItem().vm.$emit('click');
    return wrapper.vm.$nextTick();
  };

  const selectFirstCommit = () => {
    findFirstCommitDropdownItem().vm.$emit('click');
    return wrapper.vm.$nextTick();
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
    beforeEach(createComponent);

    it('initializes the dropdown with branches and tags when mounted', () => {
      return waitForRequests().then(() => {
        expect(branchesApiCallSpy).toHaveBeenCalledTimes(1);
        expect(tagsApiCallSpy).toHaveBeenCalledTimes(1);
        expect(commitApiCallSpy).not.toHaveBeenCalled();
      });
    });

    it('shows a spinner while network requests are in progress', () => {
      expect(findLoadingIcon().exists()).toBe(true);

      return waitForRequests().then(() => {
        expect(findLoadingIcon().exists()).toBe(false);
      });
    });
  });

  describe('post-initialization behavior', () => {
    describe('when the parent component provides an `id` binding', () => {
      const id = 'git-ref';

      beforeEach(() => {
        createComponent({ attrs: { id } });

        return waitForRequests();
      });

      it('adds the provided ID to the GlDropdown instance', () => {
        expect(wrapper.attributes().id).toBe(id);
      });
    });

    describe('when a ref is pre-selected', () => {
      const preselectedRef = fixtures.branches[0].name;

      beforeEach(() => {
        createComponent({ propsData: { value: preselectedRef } });

        return waitForRequests();
      });

      it('renders the pre-selected ref name', () => {
        expect(findButtonContent().text()).toBe(preselectedRef);
      });
    });

    describe('when the selected ref is updated by the parent component', () => {
      const updatedRef = fixtures.branches[0].name;

      beforeEach(() => {
        createComponent();

        return waitForRequests();
      });

      it('renders the updated ref name', () => {
        wrapper.setProps({ value: updatedRef });

        return localVue.nextTick().then(() => {
          expect(findButtonContent().text()).toBe(updatedRef);
        });
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

    describe('when the Enter is pressed', () => {
      beforeEach(() => {
        createComponent();

        return waitForRequests({ andClearMocks: true });
      });

      it('requeries the endpoints when Enter is pressed', () => {
        findSearchBox().vm.$emit('keydown', new KeyboardEvent({ key: ENTER_KEY }));

        return waitForRequests().then(() => {
          expect(branchesApiCallSpy).toHaveBeenCalledTimes(1);
          expect(tagsApiCallSpy).toHaveBeenCalledTimes(1);
        });
      });
    });

    describe('when no results are found', () => {
      beforeEach(() => {
        branchesApiCallSpy = jest.fn().mockReturnValue([200, [], { [X_TOTAL_HEADER]: '0' }]);
        tagsApiCallSpy = jest.fn().mockReturnValue([200, [], { [X_TOTAL_HEADER]: '0' }]);
        commitApiCallSpy = jest.fn().mockReturnValue([404]);

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
          createComponent();

          return waitForRequests();
        });

        it('renders the branches section in the dropdown', () => {
          expect(findBranchesSection().exists()).toBe(true);
        });

        it('renders the "Branches" heading with a total number indicator', () => {
          expect(
            findBranchesSection().find('[data-testid="section-header"]').text(),
          ).toMatchInterpolatedText('Branches 123');
        });

        it("does not render an error message in the branches section's body", () => {
          expect(branchesSectionContainsErrorMessage()).toBe(false);
        });

        it('renders each non-default branch as a selectable item', () => {
          const dropdownItems = findBranchDropdownItems();

          fixtures.branches.forEach((b, i) => {
            if (!b.default) {
              expect(dropdownItems.at(i).text()).toBe(b.name);
            }
          });
        });

        it('renders the default branch as a selectable item with a "default" badge', () => {
          const dropdownItems = findBranchDropdownItems();

          const defaultBranch = fixtures.branches.find((b) => b.default);
          const defaultBranchIndex = fixtures.branches.indexOf(defaultBranch);

          expect(trimText(dropdownItems.at(defaultBranchIndex).text())).toBe(
            `${defaultBranch.name} default`,
          );
        });
      });

      describe('when the branches search returns no results', () => {
        beforeEach(() => {
          branchesApiCallSpy = jest.fn().mockReturnValue([200, [], { [X_TOTAL_HEADER]: '0' }]);

          createComponent();

          return waitForRequests();
        });

        it('does not render the branches section in the dropdown', () => {
          expect(findBranchesSection().exists()).toBe(false);
        });
      });

      describe('when the branches search returns an error', () => {
        beforeEach(() => {
          branchesApiCallSpy = jest.fn().mockReturnValue([500]);

          createComponent();

          return waitForRequests();
        });

        it('renders the branches section in the dropdown', () => {
          expect(findBranchesSection().exists()).toBe(true);
        });

        it("renders an error message in the branches section's body", () => {
          expect(branchesSectionContainsErrorMessage()).toBe(true);
        });
      });
    });

    describe('tags', () => {
      describe('when the tags search returns results', () => {
        beforeEach(() => {
          createComponent();

          return waitForRequests();
        });

        it('renders the tags section in the dropdown', () => {
          expect(findTagsSection().exists()).toBe(true);
        });

        it('renders the "Tags" heading with a total number indicator', () => {
          expect(
            findTagsSection().find('[data-testid="section-header"]').text(),
          ).toMatchInterpolatedText('Tags 456');
        });

        it("does not render an error message in the tags section's body", () => {
          expect(tagsSectionContainsErrorMessage()).toBe(false);
        });

        it('renders each tag as a selectable item', () => {
          const dropdownItems = findTagDropdownItems();

          fixtures.tags.forEach((t, i) => {
            expect(dropdownItems.at(i).text()).toBe(t.name);
          });
        });
      });

      describe('when the tags search returns no results', () => {
        beforeEach(() => {
          tagsApiCallSpy = jest.fn().mockReturnValue([200, [], { [X_TOTAL_HEADER]: '0' }]);

          createComponent();

          return waitForRequests();
        });

        it('does not render the tags section in the dropdown', () => {
          expect(findTagsSection().exists()).toBe(false);
        });
      });

      describe('when the tags search returns an error', () => {
        beforeEach(() => {
          tagsApiCallSpy = jest.fn().mockReturnValue([500]);

          createComponent();

          return waitForRequests();
        });

        it('renders the tags section in the dropdown', () => {
          expect(findTagsSection().exists()).toBe(true);
        });

        it("renders an error message in the tags section's body", () => {
          expect(tagsSectionContainsErrorMessage()).toBe(true);
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
          expect(
            findCommitsSection().find('[data-testid="section-header"]').text(),
          ).toMatchInterpolatedText('Commits 1');
        });

        it("does not render an error message in the comits section's body", () => {
          expect(commitsSectionContainsErrorMessage()).toBe(false);
        });

        it('renders each commit as a selectable item with the short SHA and commit title', () => {
          const dropdownItems = findCommitDropdownItems();

          const { commit } = fixtures;

          expect(dropdownItems.at(0).text()).toBe(`${commit.short_id} ${commit.title}`);
        });
      });

      describe('when the commit search returns no results (i.e. a 404)', () => {
        beforeEach(() => {
          commitApiCallSpy = jest.fn().mockReturnValue([404]);

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
          commitApiCallSpy = jest.fn().mockReturnValue([500]);

          createComponent();

          updateQuery('abcd1234');

          return waitForRequests();
        });

        it('renders the commits section in the dropdown', () => {
          expect(findCommitsSection().exists()).toBe(true);
        });

        it("renders an error message in the commits section's body", () => {
          expect(commitsSectionContainsErrorMessage()).toBe(true);
        });
      });
    });

    describe('selection', () => {
      beforeEach(() => {
        createComponent();

        updateQuery(fixtures.commit.short_id);

        return waitForRequests();
      });

      it('renders a checkmark by the selected item', async () => {
        expect(findFirstBranchDropdownItem().find(GlIcon).element).toHaveClass(
          'gl-visibility-hidden',
        );

        await selectFirstBranch();

        expect(findFirstBranchDropdownItem().find(GlIcon).element).not.toHaveClass(
          'gl-visibility-hidden',
        );
      });

      describe('when a branch is seleceted', () => {
        it("displays the branch name in the dropdown's button", async () => {
          expect(findButtonContent().text()).toBe(DEFAULT_I18N.noRefSelected);

          await selectFirstBranch();

          return localVue.nextTick().then(() => {
            expect(findButtonContent().text()).toBe(fixtures.branches[0].name);
          });
        });

        it("updates the v-model binding with the branch's name", async () => {
          expect(wrapper.vm.value).toEqual('');

          await selectFirstBranch();

          expect(wrapper.vm.value).toEqual(fixtures.branches[0].name);
        });
      });

      describe('when a tag is seleceted', () => {
        it("displays the tag name in the dropdown's button", async () => {
          expect(findButtonContent().text()).toBe(DEFAULT_I18N.noRefSelected);

          await selectFirstTag();

          return localVue.nextTick().then(() => {
            expect(findButtonContent().text()).toBe(fixtures.tags[0].name);
          });
        });

        it("updates the v-model binding with the tag's name", async () => {
          expect(wrapper.vm.value).toEqual('');

          await selectFirstTag();

          expect(wrapper.vm.value).toEqual(fixtures.tags[0].name);
        });
      });

      describe('when a commit is selected', () => {
        it("displays the full SHA in the dropdown's button", async () => {
          expect(findButtonContent().text()).toBe(DEFAULT_I18N.noRefSelected);

          await selectFirstCommit();

          return localVue.nextTick().then(() => {
            expect(findButtonContent().text()).toBe(fixtures.commit.id);
          });
        });

        it("updates the v-model binding with the commit's full SHA", async () => {
          expect(wrapper.vm.value).toEqual('');

          await selectFirstCommit();

          expect(wrapper.vm.value).toEqual(fixtures.commit.id);
        });
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

    it('if a ref type becomes disabled, its section is hidden, even if it had some results in store', async () => {
      createComponent({ propsData: { enabledRefTypes: [REF_TYPE_BRANCHES, REF_TYPE_COMMITS] } });
      updateQuery('abcd1234');
      await waitForRequests();

      expect(findBranchesSection().exists()).toBe(true);
      expect(findCommitsSection().exists()).toBe(true);

      wrapper.setProps({ enabledRefTypes: [REF_TYPE_COMMITS] });
      await waitForRequests();

      expect(findBranchesSection().exists()).toBe(false);
      expect(findCommitsSection().exists()).toBe(true);
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
    const invalidClass = 'gl-inset-border-1-red-500!';
    const isInvalidClassApplied = () => wrapper.find(GlDropdown).props('toggleClass')[invalidClass];

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
      createComponent({
        scopedSlots: { footer: createFooter },
      });

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
      expect(lastCallProps).toMatchSnapshot();
    });
  });
});
