import { shallowMount } from '@vue/test-utils';
import { GlLink, GlSprintf } from '@gitlab/ui';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import HistoryItem from '~/vue_shared/components/registry/history_item.vue';
import component from '~/packages/details/components/package_history.vue';

import { mavenPackage, mockPipelineInfo } from '../../mock_data';

describe('Package History', () => {
  let wrapper;
  const defaultProps = {
    projectName: 'baz project',
    packageEntity: { ...mavenPackage },
  };

  const mountComponent = props => {
    wrapper = shallowMount(component, {
      propsData: { ...defaultProps, ...props },
      stubs: {
        HistoryItem: {
          props: HistoryItem.props,
          template: '<div data-testid="history-element"><slot></slot></div>',
        },
        GlSprintf,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findHistoryElement = testId => wrapper.find(`[data-testid="${testId}"]`);
  const findElementLink = container => container.find(GlLink);
  const findElementTimeAgo = container => container.find(TimeAgoTooltip);
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
    name            | icon          | text                                               | timeAgoTooltip                 | link
    ${'created-on'} | ${'clock'}    | ${'Test package version 1.0.0 was created'}        | ${mavenPackage.created_at}     | ${null}
    ${'updated-at'} | ${'pencil'}   | ${'Test package version 1.0.0 was updated'}        | ${mavenPackage.updated_at}     | ${null}
    ${'commit'}     | ${'commit'}   | ${'Commit sha-baz on branch branch-name'}          | ${null}                        | ${mockPipelineInfo.project.commit_url}
    ${'pipeline'}   | ${'pipeline'} | ${'Pipeline #1 triggered  by foo'}                 | ${mockPipelineInfo.created_at} | ${mockPipelineInfo.project.pipeline_url}
    ${'published'}  | ${'package'}  | ${'Published to the baz project Package Registry'} | ${mavenPackage.created_at}     | ${null}
  `('history element $name', ({ name, icon, text, timeAgoTooltip, link }) => {
    let element;

    beforeEach(() => {
      mountComponent({ packageEntity: { ...mavenPackage, pipeline: mockPipelineInfo } });
      element = findHistoryElement(name);
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
  });

  describe('when pipelineInfo is missing', () => {
    it.each(['commit', 'pipeline'])('%s history element is hidden', name => {
      mountComponent();
      expect(findHistoryElement(name).exists()).toBe(false);
    });
  });
});
