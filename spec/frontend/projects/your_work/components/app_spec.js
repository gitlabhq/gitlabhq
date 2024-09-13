import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { GlBadge, GlTabs } from '@gitlab/ui';
import projectCountsGraphQlResponse from 'test_fixtures/graphql/projects/your_work/project_counts.query.graphql.json';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import YourWorkProjectsApp from '~/projects/your_work/components/app.vue';
import TabView from '~/projects/your_work/components/tab_view.vue';
import { createRouter } from '~/projects/your_work';
import { stubComponent } from 'helpers/stub_component';
import {
  ROOT_ROUTE_NAME,
  DASHBOARD_ROUTE_NAME,
  PROJECTS_DASHBOARD_ROUTE_NAME,
  PROJECT_DASHBOARD_TABS,
  CONTRIBUTED_TAB,
  STARRED_TAB,
  PERSONAL_TAB,
  MEMBER_TAB,
  INACTIVE_TAB,
} from '~/projects/your_work/constants';
import projectCountsQuery from '~/projects/your_work/graphql/queries/project_counts.query.graphql';
import { createAlert } from '~/alert';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/alert');

Vue.use(VueRouter);
Vue.use(VueApollo);

const defaultRoute = {
  name: ROOT_ROUTE_NAME,
};

describe('YourWorkProjectsApp', () => {
  let wrapper;
  let router;
  let mockApollo;

  const successHandler = jest.fn().mockResolvedValue(projectCountsGraphQlResponse);

  const createComponent = ({ handler = successHandler, route = defaultRoute } = {}) => {
    mockApollo = createMockApollo([[projectCountsQuery, handler]]);
    router = createRouter();
    router.push(route);

    wrapper = mountExtended(YourWorkProjectsApp, {
      apolloProvider: mockApollo,
      router,
      stubs: {
        TabView: stubComponent(TabView),
      },
    });
  };

  const findPageTitle = () => wrapper.find('h1');
  const findGlTabs = () => wrapper.findComponent(GlTabs);
  const findActiveTab = () => wrapper.findByRole('tab', { selected: true });
  const findTabByName = (name) =>
    wrapper.findAllByRole('tab').wrappers.find((tab) => tab.text().includes(name));
  const getTabCount = (tabName) => findTabByName(tabName).findComponent(GlBadge).text();

  afterEach(() => {
    router = null;
    mockApollo = null;
  });

  describe('template', () => {
    it('renders Vue app with Projects h1 tag', () => {
      createComponent();

      expect(findPageTitle().text()).toBe('Projects');
    });

    describe('when project counts are loading', () => {
      beforeEach(() => {
        createComponent();
      });

      it('does not count badges', () => {
        expect(wrapper.findComponent(GlBadge).exists()).toBe(false);
      });
    });

    describe('when project counts are successfully retrieved', () => {
      beforeEach(async () => {
        createComponent();
        await waitForPromises();
      });

      it('shows count badges', () => {
        expect(getTabCount('Contributed')).toBe('2');
        expect(getTabCount('Starred')).toBe('0');
        expect(getTabCount('Personal')).toBe('0');
        expect(getTabCount('Member')).toBe('2');
        expect(getTabCount('Inactive')).toBe('0');
      });
    });

    describe('when project counts are not successfully retrieved', () => {
      const error = new Error();

      beforeEach(async () => {
        createComponent({ handler: jest.fn().mockRejectedValue(error) });
        await waitForPromises();
      });

      it('displays error alert', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred loading the project counts.',
          error,
          captureError: true,
        });
      });
    });

    it('defaults to Contributed tab as active', () => {
      expect(findActiveTab().text()).toContain('Contributed');
    });
  });

  describe.each`
    name                             | expectedTab
    ${ROOT_ROUTE_NAME}               | ${CONTRIBUTED_TAB}
    ${DASHBOARD_ROUTE_NAME}          | ${CONTRIBUTED_TAB}
    ${PROJECTS_DASHBOARD_ROUTE_NAME} | ${CONTRIBUTED_TAB}
    ${CONTRIBUTED_TAB.value}         | ${CONTRIBUTED_TAB}
    ${STARRED_TAB.value}             | ${STARRED_TAB}
    ${PERSONAL_TAB.value}            | ${PERSONAL_TAB}
    ${MEMBER_TAB.value}              | ${MEMBER_TAB}
    ${INACTIVE_TAB.value}            | ${INACTIVE_TAB}
  `('onMount when route name is $name', ({ name, expectedTab }) => {
    beforeEach(() => {
      createComponent({ route: { name } });
    });

    it('initializes to the correct tab', () => {
      expect(findActiveTab().text()).toContain(expectedTab.text);
    });

    if (expectedTab.query) {
      it('renders `TabView` component and passes `tab` prop', () => {
        expect(wrapper.findComponent(TabView).props('tab')).toMatchObject(expectedTab);
      });
    }
  });

  describe('onTabUpdate', () => {
    describe('when tab is already active', () => {
      beforeEach(() => {
        createComponent();
        router.push = jest.fn();
      });

      it('does not push new route', async () => {
        findGlTabs().vm.$emit('input', 0);

        await nextTick();

        expect(router.push).not.toHaveBeenCalled();
      });
    });

    describe('when tab is a valid tab', () => {
      beforeEach(() => {
        createComponent();
        router.push = jest.fn();
      });

      it('pushes new route correctly', async () => {
        findGlTabs().vm.$emit('input', 2);

        await nextTick();

        expect(router.push).toHaveBeenCalledWith({ name: PROJECT_DASHBOARD_TABS[2].value });
      });
    });

    describe('when tab is an invalid tab', () => {
      beforeEach(() => {
        createComponent();
        router.push = jest.fn();
      });

      it('pushes new route with default Contributed tab', async () => {
        findGlTabs().vm.$emit('input', 100);

        await nextTick();

        expect(router.push).toHaveBeenCalledWith({ name: CONTRIBUTED_TAB.value });
      });
    });

    describe('when gon.relative_url_root is set', () => {
      beforeEach(() => {
        gon.relative_url_root = '/gitlab';
        createComponent();
        router.push = jest.fn();
      });

      it('pushes new route correctly and respects relative url', async () => {
        findGlTabs().vm.$emit('input', 3);

        await nextTick();

        expect(router.options.base).toBe('/gitlab');
        expect(router.push).toHaveBeenCalledWith({ name: PROJECT_DASHBOARD_TABS[3].value });
      });
    });
  });
});
