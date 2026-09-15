import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import initExploreAnalyticsDashboards from '~/explore/analytics_dashboards';

jest.mock('~/lib/utils/vue3compat/init_vue_app', () => ({
  initVueApp: jest.fn(() => ({ mockApp: true })),
}));

describe('Explore analytics dashboards index', () => {
  const provided = () => initVueApp.mock.calls[0][0].provide;

  const setUpElement = (attributes = '') => {
    setHTMLFixture(
      `<div id="js-explore-analytics-dashboards"
        data-explore-analytics-dashboards-path="/explore/analytics_dashboards"
        ${attributes}></div>`,
    );
  };

  beforeEach(() => {
    window.gon = { current_user_id: 1 };
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('does not mount without its element', () => {
    expect(initExploreAnalyticsDashboards()).toBe(false);
    expect(initVueApp).not.toHaveBeenCalled();
  });

  // `metric_table.vue` drops the contributor count metric whenever this is
  // falsy, so the boolean has to survive the trip through the dataset.
  describe('dataSourceClickhouse', () => {
    it.each`
      attributes                               | description   | expected
      ${'data-data-source-clickhouse="true"'}  | ${'enabled'}  | ${true}
      ${'data-data-source-clickhouse="false"'} | ${'disabled'} | ${false}
      ${''}                                    | ${'absent'}   | ${false}
    `('provides $expected when the setting is $description', ({ attributes, expected }) => {
      setUpElement(attributes);

      initExploreAnalyticsDashboards();

      expect(provided().dataSourceClickhouse).toBe(expected);
    });
  });

  describe('with the element present', () => {
    beforeEach(() => {
      document.body.dataset.groupFullPath = 'gitlab-org';

      setUpElement('data-data-source-clickhouse="true"');
      initExploreAnalyticsDashboards();
    });

    afterEach(() => {
      delete document.body.dataset.groupFullPath;
    });

    it('provides the remaining app configuration', () => {
      expect(provided()).toMatchObject({
        exploreAnalyticsDashboardsPath: '/explore/analytics_dashboards',
        defaultGroupFullPath: 'gitlab-org',
        defaultProjectFullPath: null,
      });
    });
  });
});
