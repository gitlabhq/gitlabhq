import { GlSearchBoxByType, GlInfiniteScroll } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { head } from 'lodash';
import { nextTick } from 'vue';
import mockProjects from 'test_fixtures_static/projects.json';
import { trimText } from 'helpers/text_helper';
import ProjectListItem from '~/vue_shared/components/project_selector/project_list_item.vue';
import ProjectSelector from '~/vue_shared/components/project_selector/project_selector.vue';

describe('ProjectSelector component', () => {
  let wrapper;
  let vm;
  const allProjects = mockProjects;
  const searchResults = allProjects.slice(0, 5);
  let selected = [];
  selected = selected.concat(allProjects.slice(0, 3)).concat(allProjects.slice(5, 8));

  const findSearchInput = () => wrapper.findComponent(GlSearchBoxByType).find('input');
  const findLegendText = () => wrapper.find('[data-testid="legend-text"]').text();
  const search = (query) => {
    const searchInput = findSearchInput();

    searchInput.setValue(query);
    searchInput.trigger('input');
  };

  beforeEach(() => {
    wrapper = mount(ProjectSelector, {
      propsData: {
        projectSearchResults: searchResults,
        selectedProjects: selected,
        showNoResultsMessage: false,
        showMinimumSearchQueryMessage: false,
        showLoadingIndicator: false,
        showSearchErrorMessage: false,
        totalResults: searchResults.length,
      },
      attachTo: document.body,
    });

    ({ vm } = wrapper);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders the search results', () => {
    expect(wrapper.findAll('.js-project-list-item').length).toBe(5);
  });

  it(`triggers a search when the search input value changes`, () => {
    jest.spyOn(vm, '$emit').mockImplementation(() => {});
    const query = 'my test query!';
    search(query);

    expect(vm.$emit).toHaveBeenCalledWith('searched', query);
  });

  it(`includes a placeholder in the search box`, () => {
    const searchInput = findSearchInput();

    expect(searchInput.attributes('placeholder')).toBe('Search your projects');
  });

  it(`triggers a "bottomReached" event when user has scrolled to the bottom of the list`, () => {
    jest.spyOn(vm, '$emit').mockImplementation(() => {});
    wrapper.findComponent(GlInfiniteScroll).vm.$emit('bottomReached');

    expect(vm.$emit).toHaveBeenCalledWith('bottomReached');
  });

  it(`triggers a "projectClicked" event when a project is clicked`, () => {
    jest.spyOn(vm, '$emit').mockImplementation(() => {});
    wrapper.findComponent(ProjectListItem).vm.$emit('click', head(searchResults));

    expect(vm.$emit).toHaveBeenCalledWith('projectClicked', head(searchResults));
  });

  it(`shows a "no results" message if showNoResultsMessage === true`, async () => {
    wrapper.setProps({ showNoResultsMessage: true });

    await nextTick();
    const noResultsEl = wrapper.find('.js-no-results-message');

    expect(noResultsEl.exists()).toBe(true);
    expect(trimText(noResultsEl.text())).toEqual('Sorry, no projects matched your search');
  });

  it(`shows a "minimum search query" message if showMinimumSearchQueryMessage === true`, async () => {
    wrapper.setProps({ showMinimumSearchQueryMessage: true });

    await nextTick();
    const minimumSearchEl = wrapper.find('.js-minimum-search-query-message');

    expect(minimumSearchEl.exists()).toBe(true);
    expect(trimText(minimumSearchEl.text())).toEqual('Enter at least three characters to search');
  });

  it(`shows a error message if showSearchErrorMessage === true`, async () => {
    wrapper.setProps({ showSearchErrorMessage: true });

    await nextTick();
    const errorMessageEl = wrapper.find('.js-search-error-message');

    expect(errorMessageEl.exists()).toBe(true);
    expect(trimText(errorMessageEl.text())).toEqual(
      'Something went wrong, unable to search projects',
    );
  });

  describe('the search results legend', () => {
    it.each`
      count | total | expected
      ${0}  | ${0}  | ${'Showing 0 projects'}
      ${1}  | ${0}  | ${'Showing 1 project'}
      ${2}  | ${0}  | ${'Showing 2 projects'}
      ${2}  | ${3}  | ${'Showing 2 of 3 projects'}
    `(
      'is "$expected" given $count results are showing out of $total',
      async ({ count, total, expected }) => {
        search('gitlab ui');

        wrapper.setProps({
          projectSearchResults: searchResults.slice(0, count),
          totalResults: total,
        });

        await nextTick();
        expect(findLegendText()).toBe(expected);
      },
    );

    it('is not rendered without searching', () => {
      expect(findLegendText()).toBe('');
    });
  });
});
