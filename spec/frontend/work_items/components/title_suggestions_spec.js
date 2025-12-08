import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import TitleSuggestions from '~/work_items/components/title_suggestions.vue';
import TitleSuggestionsItem from '~/work_items/components/title_suggestions_item.vue';
import getIssueSuggestionsQuery from '~/work_items/graphql/issues.query.graphql';
import { mockIssueSuggestionResponse } from '../mock_data';

Vue.use(VueApollo);

const MOCK_PROJECT_PATH = 'project';
const MOCK_ISSUES_COUNT = mockIssueSuggestionResponse.data.project.issues.edges.length;

describe('Issue title suggestions component', () => {
  let wrapper;
  let mockApollo;

  function createComponent({
    search = 'search',
    queryResponse = jest.fn().mockResolvedValue(mockIssueSuggestionResponse),
  } = {}) {
    mockApollo = createMockApollo([[getIssueSuggestionsQuery, queryResponse]]);

    wrapper = shallowMount(TitleSuggestions, {
      propsData: {
        search,
        projectPath: MOCK_PROJECT_PATH,
      },
      apolloProvider: mockApollo,
    });
  }

  const waitForDebounce = () => {
    jest.runOnlyPendingTimers();
    return waitForPromises();
  };

  const findCrudComponent = () => wrapper.findComponent(CrudComponent);

  afterEach(() => {
    mockApollo = null;
  });

  it('does not render with empty search', async () => {
    createComponent({ search: '' });
    await waitForDebounce();

    expect(findCrudComponent().isVisible()).toBe(false);
  });

  it('does not render when loading', () => {
    createComponent();
    expect(findCrudComponent().isVisible()).toBe(false);
  });

  it('does not render with empty issues data', async () => {
    const emptyIssuesResponse = {
      data: {
        project: {
          id: 'gid://gitlab/Project/1',
          issues: {
            edges: [],
          },
        },
      },
    };

    createComponent({ queryResponse: jest.fn().mockResolvedValue(emptyIssuesResponse) });
    await waitForDebounce();

    expect(findCrudComponent().isVisible()).toBe(false);
  });

  it('does not render when the path is not a valid project path', async () => {
    const emptyProjectResponse = {
      data: {
        project: null,
      },
    };

    createComponent({ queryResponse: jest.fn().mockResolvedValue(emptyProjectResponse) });
    await waitForDebounce();

    expect(wrapper.isVisible()).toBe(false);
  });

  describe('with data', () => {
    beforeEach(async () => {
      createComponent();
      await waitForDebounce();
    });

    it('renders component', () => {
      expect(findCrudComponent().isVisible()).toBe(true);
      expect(findCrudComponent().props()).toMatchObject({
        title: 'Similar issues',
        count: MOCK_ISSUES_COUNT,
      });
    });

    it('renders help text', () => {
      expect(wrapper.text()).toContain(
        'These existing issues have a similar title. It might be better to comment there instead of creating another similar issue.',
      );
    });

    it('renders list of issues', () => {
      expect(wrapper.findAllComponents(TitleSuggestionsItem)).toHaveLength(MOCK_ISSUES_COUNT);
    });

    it('adds margin class to first item', () => {
      expect(wrapper.findAll('li').at(0).classes()).toContain('gl-mb-4');
    });

    it('does not add margin class to last item', () => {
      expect(wrapper.findAll('li').at(1).classes()).not.toContain('gl-mb-4');
    });
  });
});
