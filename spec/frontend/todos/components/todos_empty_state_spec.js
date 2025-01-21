import { GlEmptyState, GlLink, GlSprintf } from '@gitlab/ui';
import emptyTodosAllDoneSvg from '@gitlab/svgs/dist/illustrations/empty-todos-all-done-md.svg';
import emptyTodosSvg from '@gitlab/svgs/dist/illustrations/empty-todos-md.svg';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TodosEmptyState from '~/todos/components/todos_empty_state.vue';
import { TODO_EMPTY_TITLE_POOL, TABS_INDICES } from '~/todos/constants';

describe('TodosEmptyState', () => {
  let wrapper;

  const createComponent = (props = {}, currentTab = TABS_INDICES.pending) => {
    wrapper = shallowMountExtended(TodosEmptyState, {
      propsData: {
        isFiltered: false,
        ...props,
      },
      provide: {
        issuesDashboardPath: '/dashboard/issues',
        mergeRequestsDashboardPath: '/dashboard/merge_requests',
        currentTab,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findDocLink = () => wrapper.findByTestId('doc-link');

  it('renders the empty state component', () => {
    createComponent();
    expect(wrapper.findComponent(GlEmptyState).exists()).toBe(true);
  });

  describe('when not filtered', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders a random title', () => {
      const title = wrapper.findComponent(GlEmptyState).props('title');
      expect(TODO_EMPTY_TITLE_POOL).toContain(title);
    });

    it('uses the correct illustration', () => {
      expect(wrapper.findComponent(GlEmptyState).props('svgPath')).toBe(emptyTodosAllDoneSvg);
    });

    it('renders a description', () => {
      expect(wrapper.findComponent(GlSprintf).exists()).toBe(true);
    });

    it('renders links to assigned issues and merge requests', () => {
      const links = wrapper.findAllComponents(GlLink);
      expect(links.at(0).attributes('href')).toBe('/dashboard/issues');
      expect(links.at(1).attributes('href')).toBe('/dashboard/merge_requests');
    });

    it('renders a link to the documentation', () => {
      const docLink = findDocLink();
      expect(docLink.attributes('href')).toBe(TodosEmptyState.docsPath);
      expect(docLink.text()).toBe('What actions create to-do items?');
    });
  });

  describe('when filtered', () => {
    beforeEach(() => {
      createComponent({ isFiltered: true });
    });

    it('renders the correct title', () => {
      expect(wrapper.findComponent(GlEmptyState).props('title')).toBe(
        'Sorry, your filter produced no results',
      );
    });

    it('does not render a description', () => {
      expect(wrapper.findComponent(GlSprintf).exists()).toBe(false);
    });

    it('uses the correct illustration', () => {
      expect(wrapper.findComponent(GlEmptyState).props('svgPath')).toBe(emptyTodosSvg);
    });
  });

  describe('when on "Snoozed" tab', () => {
    beforeEach(() => {
      createComponent({ isFiltered: false }, TABS_INDICES.snoozed);
    });

    it('renders the correct title', () => {
      expect(wrapper.findComponent(GlEmptyState).props('title')).toBe(
        'There are no snoozed to-do items yet.',
      );
    });

    it('renders the correct a description', () => {
      expect(wrapper.findComponent(GlEmptyState).text()).toContain(
        'When to-do items are snoozed, they will appear here.',
      );
    });

    it('uses the correct illustration', () => {
      expect(wrapper.findComponent(GlEmptyState).props('svgPath')).toBe(emptyTodosSvg);
    });
  });

  describe('when on "Done" tab', () => {
    beforeEach(() => {
      createComponent({ isFiltered: false }, TABS_INDICES.done);
    });

    it('renders the correct title', () => {
      expect(wrapper.findComponent(GlEmptyState).props('title')).toBe(
        'There are no done to-do items yet.',
      );
    });

    it('does not render a description', () => {
      expect(wrapper.findComponent(GlSprintf).exists()).toBe(false);
    });

    it('uses the correct illustration', () => {
      expect(wrapper.findComponent(GlEmptyState).props('svgPath')).toBe(emptyTodosSvg);
    });
  });
});
