import { nextTick } from 'vue';
import { GlTabs } from '@gitlab/ui';
import { TEST_HOST } from 'helpers/test_constants';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { updateHistory } from '~/lib/utils/url_utility';
import YourWorkProjectsApp from '~/projects/your_work/components/app.vue';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import {
  PROJECT_DASHBOARD_TABS,
  CONTRIBUTED_TAB,
  STARRED_TAB,
  PERSONAL_TAB,
  MEMBER_TAB,
} from 'ee_else_ce/projects/your_work/constants';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  updateHistory: jest.fn(),
}));

describe('YourWorkProjectsApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mountExtended(YourWorkProjectsApp);
  };

  const findPageTitle = () => wrapper.find('h1');
  const findGlTabs = () => wrapper.findComponent(GlTabs);
  const findAllTabTitles = () => wrapper.findAllByTestId('projects-dashboard-tab-title');
  const findActiveTab = () => wrapper.find('.tab-pane.active');

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
    path                                 | expectedTab
    ${'/'}                               | ${CONTRIBUTED_TAB}
    ${'/dashboard'}                      | ${CONTRIBUTED_TAB}
    ${'/dashboard/projects'}             | ${CONTRIBUTED_TAB}
    ${'/dashboard/projects/contributed'} | ${CONTRIBUTED_TAB}
    ${'/dashboard/projects/starred'}     | ${STARRED_TAB}
    ${'/dashboard/projects/personal'}    | ${PERSONAL_TAB}
    ${'/dashboard/projects/member'}      | ${MEMBER_TAB}
    ${'/dashboard/projects/fake'}        | ${CONTRIBUTED_TAB}
  `('onMount when path is $path', ({ path, expectedTab }) => {
    useMockLocationHelper();
    beforeEach(() => {
      delete window.location;
      window.location = new URL(`${TEST_HOST}/${path}`);

      createComponent();
    });

    it('initializes to the correct tab', () => {
      expect(findActiveTab().text()).toContain(expectedTab.text);
    });
  });

  describe('onTabUpdate', () => {
    describe('when tab is already active', () => {
      beforeEach(() => {
        createComponent();
      });

      it('does not update the url path', async () => {
        findGlTabs().vm.$emit('input', 0);

        await nextTick();

        expect(updateHistory).not.toHaveBeenCalled();
      });
    });

    describe('when tab is a valid tab', () => {
      beforeEach(() => {
        createComponent();
      });

      it('updates the url path correctly', async () => {
        findGlTabs().vm.$emit('input', 2);

        await nextTick();

        expect(updateHistory).toHaveBeenCalledWith({
          url: `/dashboard/projects/${PROJECT_DASHBOARD_TABS[2].value}`,
          replace: true,
        });
      });
    });

    describe('when tab is an invalid tab', () => {
      beforeEach(() => {
        createComponent();
      });

      it('update the url path with the default Contributed tab', async () => {
        findGlTabs().vm.$emit('input', 100);

        await nextTick();

        expect(updateHistory).toHaveBeenCalledWith({
          url: `/dashboard/projects/${CONTRIBUTED_TAB.value}`,
          replace: true,
        });
      });
    });

    describe('when gon.relative_url_root is set', () => {
      beforeEach(() => {
        gon.relative_url_root = '/gitlab';
        createComponent();
      });

      it('update the url path correctly with relative url', async () => {
        findGlTabs().vm.$emit('input', 3);

        await nextTick();

        expect(updateHistory).toHaveBeenCalledWith({
          url: `/gitlab/dashboard/projects/${PROJECT_DASHBOARD_TABS[3].value}`,
          replace: true,
        });
      });
    });
  });
});
