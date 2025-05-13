import { mount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import ClickhouseHelpPopover from '~/projects/pipelines/charts/components/clickhouse_help_popover.vue';
import HelpPopover from '~/vue_shared/components/help_popover.vue';

describe('DashboardHeader', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mount(ClickhouseHelpPopover, {
      stubs: {
        HelpPopover,
      },
    });
  };

  const findHelpPopover = () => wrapper.findComponent(HelpPopover);

  it('when ci_improved_project_pipeline_analytics is enabled, it is rendered', () => {
    createComponent();

    expect(findHelpPopover().text()).toContain('Try ClickHouse for advanced analytics');
    expect(findHelpPopover().text()).toContain(
      'ClickHouse can provide a more comprehensive pipelines analytics for your project.',
    );
    expect(findHelpPopover().findComponent(GlLink).props('href')).toBe(
      '/help/administration/analytics',
    );
  });
});
