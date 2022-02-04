import { GlLink, GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MetricPopover from '~/analytics/shared/components/metric_popover.vue';

const MOCK_METRIC = {
  key: 'deployment-frequency',
  label: 'Deployment Frequency',
  value: '10.0',
  unit: 'per day',
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
  const findAllMetricLinks = () => wrapper.findAll('[data-testid="metric-link"]');
  const findMetricDescription = () => wrapper.findByTestId('metric-description');
  const findMetricDocsLink = () => wrapper.findByTestId('metric-docs-link');
  const findMetricDocsLinkIcon = () => findMetricDocsLink().find(GlIcon);

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the metric label', () => {
    wrapper = createComponent({ metric: MOCK_METRIC });
    expect(findMetricLabel().text()).toBe(MOCK_METRIC.label);
  });

  it('renders the metric description', () => {
    wrapper = createComponent({ metric: MOCK_METRIC });
    expect(findMetricDescription().text()).toBe(MOCK_METRIC.description);
  });

  describe('with links', () => {
    const links = [
      {
        name: 'Deployment frequency',
        url: '/groups/gitlab-org/-/analytics/ci_cd?tab=deployment-frequency',
        label: 'Dashboard',
      },
      {
        name: 'Another link',
        url: '/groups/gitlab-org/-/analytics/another-link',
        label: 'Another link',
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
      hasDocsLink | allLinks         | displayedMetricLinks
      ${true}     | ${linksWithDocs} | ${links}
      ${false}    | ${links}         | ${links}
    `(
      'when one link has docs_link=$hasDocsLink',
      ({ hasDocsLink, allLinks, displayedMetricLinks }) => {
        beforeEach(() => {
          wrapper = createComponent({ metric: { ...MOCK_METRIC, links: allLinks } });
        });

        displayedMetricLinks.forEach((link, idx) => {
          it(`renders a link for "${link.name}"`, () => {
            const allLinkContainers = findAllMetricLinks();

            expect(allLinkContainers.at(idx).text()).toContain(link.name);
            expect(allLinkContainers.at(idx).find(GlLink).attributes('href')).toBe(link.url);
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
      },
    );
  });
});
