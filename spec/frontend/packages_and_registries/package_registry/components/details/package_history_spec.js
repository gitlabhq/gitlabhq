import { GlLink, GlSprintf } from '@gitlab/ui';
import { stubComponent } from 'helpers/stub_component';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  packageData,
  packagePipelines,
} from 'jest/packages_and_registries/package_registry/mock_data';
import { HISTORY_PIPELINES_LIMIT } from '~/packages/details/constants';
import component from '~/packages_and_registries/package_registry/components/details/package_history.vue';
import HistoryItem from '~/vue_shared/components/registry/history_item.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

describe('Package History', () => {
  let wrapper;
  const defaultProps = {
    projectName: 'baz project',
    packageEntity: { ...packageData() },
  };

  const [onePipeline] = packagePipelines();

  const createPipelines = (amount) =>
    [...Array(amount)].map((x, index) => packagePipelines({ id: index + 1 })[0]);

  const mountComponent = (props) => {
    wrapper = shallowMountExtended(component, {
      propsData: { ...defaultProps, ...props },
      stubs: {
        HistoryItem: stubComponent(HistoryItem, {
          template: '<div data-testid="history-element"><slot></slot></div>',
        }),
        GlSprintf,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findHistoryElement = (testId) => wrapper.findByTestId(testId);
  const findElementLink = (container) => container.findComponent(GlLink);
  const findElementTimeAgo = (container) => container.findComponent(TimeAgoTooltip);
  const findTitle = () => wrapper.findByTestId('title');
  const findTimeline = () => wrapper.findByTestId('timeline');

  it('has the correct title', () => {
    mountComponent();

    const title = findTitle();

    expect(title.exists()).toBe(true);
    expect(title.text()).toBe('History');
  });

  it('has a timeline container', () => {
    mountComponent();

    const title = findTimeline();

    expect(title.exists()).toBe(true);
    expect(title.classes()).toEqual(
      expect.arrayContaining(['timeline', 'main-notes-list', 'notes']),
    );
  });

  describe.each`
    name                         | amount                         | icon          | text                                                                                                           | timeAgoTooltip             | link
    ${'created-on'}              | ${HISTORY_PIPELINES_LIMIT + 2} | ${'clock'}    | ${'@gitlab-org/package-15 version 1.0.0 was first created'}                                                    | ${packageData().createdAt} | ${null}
    ${'first-pipeline-commit'}   | ${HISTORY_PIPELINES_LIMIT + 2} | ${'commit'}   | ${'Created by commit #b83d6e39 on branch master'}                                                              | ${null}                    | ${onePipeline.commitPath}
    ${'first-pipeline-pipeline'} | ${HISTORY_PIPELINES_LIMIT + 2} | ${'pipeline'} | ${'Built by pipeline #1 triggered  by Administrator'}                                                          | ${onePipeline.createdAt}   | ${onePipeline.path}
    ${'published'}               | ${HISTORY_PIPELINES_LIMIT + 2} | ${'package'}  | ${'Published to the baz project Package Registry'}                                                             | ${packageData().createdAt} | ${null}
    ${'archived'}                | ${HISTORY_PIPELINES_LIMIT + 2} | ${'history'}  | ${'Package has 1 archived update'}                                                                             | ${null}                    | ${null}
    ${'archived'}                | ${HISTORY_PIPELINES_LIMIT + 3} | ${'history'}  | ${'Package has 2 archived updates'}                                                                            | ${null}                    | ${null}
    ${'pipeline-entry'}          | ${HISTORY_PIPELINES_LIMIT + 2} | ${'pencil'}   | ${'Package updated by commit #b83d6e39 on branch master, built by pipeline #3, and published to the registry'} | ${packageData().createdAt} | ${onePipeline.commitPath}
  `(
    'with $amount pipelines history element $name',
    ({ name, icon, text, timeAgoTooltip, link, amount }) => {
      let element;

      beforeEach(() => {
        const packageEntity = { ...packageData(), pipelines: { nodes: createPipelines(amount) } };
        mountComponent({
          packageEntity,
        });
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
});
