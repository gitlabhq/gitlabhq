import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { stubComponent } from 'helpers/stub_component';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  packageData,
  packagePipelines,
  packagePipelinesQuery,
} from 'jest/packages_and_registries/package_registry/mock_data';
import { HISTORY_PIPELINES_LIMIT } from '~/packages_and_registries/shared/constants';
import component from '~/packages_and_registries/package_registry/components/details/package_history.vue';
import PackageHistoryLoader from '~/packages_and_registries/package_registry/components/details/package_history_loader.vue';
import HistoryItem from '~/vue_shared/components/registry/history_item.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import waitForPromises from 'helpers/wait_for_promises';
import getPackagePipelines from '~/packages_and_registries/package_registry/graphql/queries/get_package_pipelines.query.graphql';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import {
  TRACKING_ACTION_CLICK_PIPELINE_LINK,
  TRACKING_ACTION_CLICK_COMMIT_LINK,
  TRACKING_LABEL_PACKAGE_HISTORY,
} from '~/packages_and_registries/package_registry/constants';

Vue.use(VueApollo);

describe('Package History', () => {
  let wrapper;
  let apolloProvider;

  const defaultProps = {
    projectName: 'baz project',
    packageEntity: { ...packageData() },
  };

  const [onePipeline] = packagePipelines();

  const createPipelines = (amount) =>
    [...Array(amount)].map((x, index) => packagePipelines({ id: index + 1 })[0]);

  const mountComponent = ({
    props = {},
    resolver = jest.fn().mockResolvedValue(packagePipelinesQuery()),
  } = {}) => {
    const requestHandlers = [[getPackagePipelines, resolver]];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(component, {
      apolloProvider,
      propsData: { ...defaultProps, ...props },
      stubs: {
        HistoryItem: stubComponent(HistoryItem, {
          template: '<div data-testid="history-element"><slot></slot></div>',
        }),
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    jest.spyOn(Sentry, 'captureException').mockImplementation();
  });

  const findPackageHistoryLoader = () => wrapper.findComponent(PackageHistoryLoader);
  const findHistoryElement = (testId) => wrapper.findByTestId(testId);
  const findElementLink = (container) => container.findComponent(GlLink);
  const findElementTimeAgo = (container) => container.findComponent(TimeAgoTooltip);
  const findPackageHistoryAlert = () => wrapper.findComponent(GlAlert);
  const findTitle = () => wrapper.findByTestId('title');
  const findTimeline = () => wrapper.findByTestId('timeline');

  it('renders the loading container when loading', () => {
    mountComponent();

    expect(findPackageHistoryLoader().exists()).toBe(true);
  });

  it('does not render the loading container once resolved', async () => {
    mountComponent();
    await waitForPromises();

    expect(findPackageHistoryLoader().exists()).toBe(false);
    expect(Sentry.captureException).not.toHaveBeenCalled();
  });

  it('has the correct title', async () => {
    mountComponent();
    await waitForPromises();

    const title = findTitle();

    expect(title.exists()).toBe(true);
    expect(title.text()).toBe('History');
  });

  it('has a timeline container', async () => {
    mountComponent();
    await waitForPromises();

    const title = findTimeline();

    expect(title.exists()).toBe(true);
    expect(title.classes()).toEqual(
      expect.arrayContaining(['timeline', 'main-notes-list', 'notes']),
    );
  });

  it('does not render gl-alert', () => {
    mountComponent();

    expect(findPackageHistoryAlert().exists()).toBe(false);
  });

  it('renders gl-alert if load fails', async () => {
    mountComponent({ resolver: jest.fn().mockRejectedValue() });

    await waitForPromises();

    expect(findPackageHistoryAlert().exists()).toBe(true);
    expect(findPackageHistoryAlert().text()).toEqual(
      'Something went wrong while fetching the package history.',
    );
    expect(Sentry.captureException).toHaveBeenCalled();
  });

  describe.each`
    name                         | amount                         | icon          | text                                                                                                          | timeAgoTooltip             | link
    ${'created-on'}              | ${HISTORY_PIPELINES_LIMIT + 2} | ${'clock'}    | ${'@gitlab-org/package-15 version 1.0.0 was first created'}                                                   | ${packageData().createdAt} | ${null}
    ${'first-pipeline-commit'}   | ${HISTORY_PIPELINES_LIMIT + 2} | ${'commit'}   | ${'Created by commit b83d6e39 on branch master'}                                                              | ${null}                    | ${onePipeline.commitPath}
    ${'first-pipeline-pipeline'} | ${HISTORY_PIPELINES_LIMIT + 2} | ${'pipeline'} | ${'Built by pipeline #1 triggered  by Administrator'}                                                         | ${onePipeline.createdAt}   | ${onePipeline.path}
    ${'published'}               | ${HISTORY_PIPELINES_LIMIT + 2} | ${'package'}  | ${'Published to the baz project Package Registry'}                                                            | ${packageData().createdAt} | ${null}
    ${'archived'}                | ${HISTORY_PIPELINES_LIMIT + 2} | ${'history'}  | ${'Package has 1 archived update'}                                                                            | ${null}                    | ${null}
    ${'archived'}                | ${HISTORY_PIPELINES_LIMIT + 3} | ${'history'}  | ${'Package has 2 archived updates'}                                                                           | ${null}                    | ${null}
    ${'pipeline-entry'}          | ${HISTORY_PIPELINES_LIMIT + 2} | ${'pencil'}   | ${'Package updated by commit b83d6e39 on branch master, built by pipeline #3, and published to the registry'} | ${packageData().createdAt} | ${onePipeline.commitPath}
  `(
    'with $amount pipelines history element $name',
    ({ name, icon, text, timeAgoTooltip, link, amount }) => {
      let element;

      beforeEach(async () => {
        const packageEntity = { ...packageData() };
        const pipelinesResolver = jest
          .fn()
          .mockResolvedValue(packagePipelinesQuery(createPipelines(amount)));

        mountComponent({
          props: {
            packageEntity,
          },
          resolver: pipelinesResolver,
        });

        await waitForPromises();

        element = findHistoryElement(name);
      });

      it('exists', () => {
        expect(element.exists()).toBe(true);
      });

      it('has the correct icon', () => {
        expect(element.props('icon')).toBe(icon);
      });

      it('has the correct text', () => {
        expect(element.text()).toBe(text);
      });

      it('time-ago tooltip', () => {
        const timeAgo = findElementTimeAgo(element);
        const exist = Boolean(timeAgoTooltip);

        expect(timeAgo.exists()).toBe(exist);
        if (exist) {
          expect(timeAgo.props('time')).toBe(timeAgoTooltip);
        }
      });

      it('link', () => {
        const linkElement = findElementLink(element);
        const exist = Boolean(link);
        expect(linkElement.exists()).toBe(exist);
        if (exist) {
          expect(linkElement.attributes('href')).toBe(link);
        }
      });
    },
  );
  describe('tracking', () => {
    let eventSpy;
    const category = 'UI::Packages';

    beforeEach(() => {
      eventSpy = mockTracking(undefined, undefined, jest.spyOn);
      mountComponent();
    });

    afterEach(() => {
      unmockTracking();
    });

    it('clicking pipeline link tracks the right action', () => {
      wrapper.vm.trackPipelineClick();
      expect(eventSpy).toHaveBeenCalledWith(category, TRACKING_ACTION_CLICK_PIPELINE_LINK, {
        category,
        label: TRACKING_LABEL_PACKAGE_HISTORY,
      });
    });

    it('clicking commit link tracks the right action', () => {
      wrapper.vm.trackCommitClick();
      expect(eventSpy).toHaveBeenCalledWith(category, TRACKING_ACTION_CLICK_COMMIT_LINK, {
        category,
        label: TRACKING_LABEL_PACKAGE_HISTORY,
      });
    });
  });
});
