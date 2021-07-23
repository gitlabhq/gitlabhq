import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { stubComponent } from 'helpers/stub_component';
import { mavenPackage, mockPipelineInfo } from 'jest/packages/mock_data';
import { HISTORY_PIPELINES_LIMIT } from '~/packages/details/constants';
import component from '~/packages_and_registries/package_registry/components/details/package_history.vue';
import HistoryItem from '~/vue_shared/components/registry/history_item.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

describe('Package History', () => {
  let wrapper;
  const defaultProps = {
    projectName: 'baz project',
    packageEntity: { ...mavenPackage },
  };

  const createPipelines = (amount) =>
    [...Array(amount)].map((x, index) => ({ ...mockPipelineInfo, id: index + 1 }));

  const mountComponent = (props) => {
    wrapper = shallowMount(component, {
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
    wrapper = null;
  });

  const findHistoryElement = (testId) => wrapper.find(`[data-testid="${testId}"]`);
  const findElementLink = (container) => container.find(GlLink);
  const findElementTimeAgo = (container) => container.find(TimeAgoTooltip);
  const findTitle = () => wrapper.find('[data-testid="title"]');
  const findTimeline = () => wrapper.find('[data-testid="timeline"]');

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
    name                         | amount                         | icon          | text                                                                                                               | timeAgoTooltip                 | link
    ${'created-on'}              | ${HISTORY_PIPELINES_LIMIT + 2} | ${'clock'}    | ${'Test package version 1.0.0 was first created'}                                                                  | ${mavenPackage.created_at}     | ${null}
    ${'first-pipeline-commit'}   | ${HISTORY_PIPELINES_LIMIT + 2} | ${'commit'}   | ${'Created by commit #sha-baz on branch branch-name'}                                                              | ${null}                        | ${mockPipelineInfo.project.commit_url}
    ${'first-pipeline-pipeline'} | ${HISTORY_PIPELINES_LIMIT + 2} | ${'pipeline'} | ${'Built by pipeline #1 triggered  by foo'}                                                                        | ${mockPipelineInfo.created_at} | ${mockPipelineInfo.project.pipeline_url}
    ${'published'}               | ${HISTORY_PIPELINES_LIMIT + 2} | ${'package'}  | ${'Published to the baz project Package Registry'}                                                                 | ${mavenPackage.created_at}     | ${null}
    ${'archived'}                | ${HISTORY_PIPELINES_LIMIT + 2} | ${'history'}  | ${'Package has 1 archived update'}                                                                                 | ${null}                        | ${null}
    ${'archived'}                | ${HISTORY_PIPELINES_LIMIT + 3} | ${'history'}  | ${'Package has 2 archived updates'}                                                                                | ${null}                        | ${null}
    ${'pipeline-entry'}          | ${HISTORY_PIPELINES_LIMIT + 2} | ${'pencil'}   | ${'Package updated by commit #sha-baz on branch branch-name, built by pipeline #3, and published to the registry'} | ${mavenPackage.created_at}     | ${mockPipelineInfo.project.commit_url}
  `(
    'with $amount pipelines history element $name',
    ({ name, icon, text, timeAgoTooltip, link, amount }) => {
      let element;

      beforeEach(() => {
        mountComponent({
          packageEntity: { ...mavenPackage, pipelines: createPipelines(amount) },
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
