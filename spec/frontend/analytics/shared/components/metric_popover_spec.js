import { GlLink, GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MetricPopover from '~/analytics/shared/components/metric_popover.vue';
import { METRIC_POPOVER_LABEL } from '~/analytics/shared/constants';

const MOCK_METRIC = {
  key: 'deployment-frequency',
  label: 'Deployment frequency',
  value: '10.0',
  unit: '/day',
  description: 'Average number of deployments to production per day.',
  links: [],
};

describe('MetricPopover', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    return shallowMountExtended(MetricPopover, {
      propsData: {
        target: 'deployment-frequency',
        ...props,
      },
      stubs: {
        'gl-popover': { template: '<div><slot name="title"></slot><slot></slot></div>' },
      },
    });
  };

  const findMetricLabel = () => wrapper.findByTestId('metric-label');
  const findMetricLink = () => wrapper.find('[data-testid="metric-link"]');
  const findMetricDescription = () => wrapper.findByTestId('metric-description');
  const findMetricDocsLink = () => wrapper.findByTestId('metric-docs-link');
  const findMetricDocsLinkIcon = () => findMetricDocsLink().findComponent(GlIcon);
  const findMetricDetailsIcon = () => findMetricLink().findComponent(GlIcon);

  it('renders the metric label', () => {
    wrapper = createComponent({ metric: MOCK_METRIC });
    expect(findMetricLabel().text()).toBe(MOCK_METRIC.label);
  });

  it('renders the metric description', () => {
    wrapper = createComponent({ metric: MOCK_METRIC });
    expect(findMetricDescription().text()).toBe(MOCK_METRIC.description);
  });

  describe('with links', () => {
    const METRIC_NAME = 'Deployment frequency';
    const LINK_URL = '/groups/gitlab-org/-/analytics/ci_cd?tab=deployment-frequency';
    const links = [
      {
        name: METRIC_NAME,
        url: LINK_URL,
        label: 'Dashboard',
      },
    ];
    const docsLink = {
      name: 'Deployment frequency',
      url: '/help/user/analytics/index#definitions',
      label: 'Go to docs',
      docs_link: true,
    };
    const linksWithDocs = [...links, docsLink];

    describe.each`
      hasDocsLink | allLinks
      ${true}     | ${linksWithDocs}
      ${false}    | ${links}
    `('when one link has docs_link=$hasDocsLink', ({ hasDocsLink, allLinks }) => {
      beforeEach(() => {
        wrapper = createComponent({ metric: { ...MOCK_METRIC, links: allLinks } });
      });

      describe('Metric title row', () => {
        it(`renders a link for "${METRIC_NAME}"`, () => {
          expect(findMetricLink().text()).toContain(METRIC_POPOVER_LABEL);
          expect(findMetricLink().findComponent(GlLink).attributes('href')).toBe(LINK_URL);
        });

        it('renders the chart icon', () => {
          expect(findMetricDetailsIcon().attributes('name')).toBe('chart');
        });
      });

      it(`${hasDocsLink ? 'renders' : "doesn't render"} a docs link`, () => {
        expect(findMetricDocsLink().exists()).toBe(hasDocsLink);

        if (hasDocsLink) {
          expect(findMetricDocsLink().attributes('href')).toBe(docsLink.url);
          expect(findMetricDocsLink().text()).toBe(docsLink.label);
          expect(findMetricDocsLinkIcon().attributes('name')).toBe('external-link');
        }
      });
    });
  });
});
