import { GlTable, GlBadge, GlEmptyState, GlLink } from '@gitlab/ui';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import DevopsScore from '~/analytics/devops_report/components/devops_score.vue';
import {
  devopsScoreMetricsData,
  devopsReportDocsPath,
  noDataImagePath,
  devopsScoreTableHeaders,
} from '../mock_data';

describe('DevopsScore', () => {
  let wrapper;

  const createComponent = ({ devopsScoreMetrics = devopsScoreMetricsData } = {}) => {
    wrapper = extendedWrapper(
      mount(DevopsScore, {
        provide: {
          devopsScoreMetrics,
          devopsReportDocsPath,
          noDataImagePath,
        },
      }),
    );
  };

  const findTable = () => wrapper.findComponent(GlTable);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findCol = (testId) => findTable().find(`[data-testid="${testId}"]`);
  const findUsageCol = () => findCol('usageCol');
  const findDevopsScoreApp = () => wrapper.findByTestId('devops-score-app');

  describe('with no data', () => {
    beforeEach(() => {
      createComponent({ devopsScoreMetrics: {} });
    });

    describe('empty state', () => {
      it('displays the empty state', () => {
        expect(findEmptyState().exists()).toBe(true);
      });

      it('displays the correct message', () => {
        expect(findEmptyState().text()).toBe(
          'Data is still calculating... It may be several days before you see feature usage data. See example DevOps Score page in our documentation.',
        );
      });

      it('contains a link to the feature documentation', () => {
        expect(wrapper.findComponent(GlLink).exists()).toBe(true);
      });
    });

    it('does not display the devops score app', () => {
      expect(findDevopsScoreApp().exists()).toBe(false);
    });
  });

  describe('with data', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not display the empty state', () => {
      expect(findEmptyState().exists()).toBe(false);
    });

    it('displays the devops score app', () => {
      expect(findDevopsScoreApp().exists()).toBe(true);
    });

    describe('devops score app', () => {
      it('displays the title note', () => {
        expect(wrapper.findByTestId('devops-score-note-text').text()).toBe(
          'DevOps score metrics are based on usage over the last 30 days. Last updated: 2020-06-29 08:16.',
        );
      });

      it('displays the single stat section', () => {
        const component = wrapper.findComponent(GlSingleStat);

        expect(component.exists()).toBe(true);
        expect(component.props('value')).toBe(devopsScoreMetricsData.averageScore.value);
      });

      describe('devops score table', () => {
        it('displays the table', () => {
          expect(findTable().exists()).toBe(true);
        });

        describe('table headings', () => {
          let headers;

          beforeEach(() => {
            headers = findTable().findAll("[data-testid='header']");
          });

          it('displays the correct number of headings', () => {
            expect(headers).toHaveLength(devopsScoreTableHeaders.length);
          });

          describe.each(devopsScoreTableHeaders)('header fields', ({ label, index }) => {
            let headerWrapper;

            beforeEach(() => {
              headerWrapper = headers.at(index);
            });

            it(`displays the correct table heading text for "${label}"`, () => {
              expect(headerWrapper.text()).toContain(label);
            });
          });
        });

        describe('table columns', () => {
          describe('Your usage', () => {
            it('displays the corrrect value', () => {
              expect(findUsageCol().text()).toContain('3.2');
            });

            it('displays the corrrect badge', () => {
              const badge = findUsageCol().find(GlBadge);

              expect(badge.exists()).toBe(true);
              expect(badge.props('variant')).toBe('muted');
              expect(badge.text()).toBe('Low');
            });
          });
        });
      });
    });
  });
});
