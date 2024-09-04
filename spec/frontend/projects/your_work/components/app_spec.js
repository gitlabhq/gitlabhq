import Vue, { nextTick } from 'vue';
import VueRouter from 'vue-router';
import { GlTabs } from '@gitlab/ui';
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
} from 'ee_else_ce/projects/your_work/constants';

Vue.use(VueRouter);

const defaultRoute = {
  name: ROOT_ROUTE_NAME,
};

describe('YourWorkProjectsApp', () => {
  let wrapper;
  let router;

  const createComponent = ({ route = defaultRoute } = {}) => {
    router = createRouter();
    router.push(route);

    wrapper = mountExtended(YourWorkProjectsApp, {
      router,
      stubs: {
        TabView: stubComponent(TabView),
      },
    });
  };

  const findPageTitle = () => wrapper.find('h1');
  const findGlTabs = () => wrapper.findComponent(GlTabs);
  const findAllTabTitles = () => wrapper.findAllByTestId('projects-dashboard-tab-title');
  const findActiveTab = () => wrapper.findByRole('tab', { selected: true });

  afterEach(() => {
    router = null;
  });

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders Vue app with Projects h1 tag', () => {
      expect(findPageTitle().text()).toBe('Projects');
    });

    it('renders all expected tabs with counts', () => {
      const wrapperTabTitles = findAllTabTitles().wrappers.map((w) => w.text().replace(/ /g, ''));
      const expectedTabTitles = PROJECT_DASHBOARD_TABS.map(({ text }) => `${text}0`);

      expect(wrapperTabTitles).toStrictEqual(expectedTabTitles);
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
