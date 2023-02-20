import { GlTable, GlIcon, GlLink } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { INTEGRATION_TYPE_SLACK } from '~/integrations/constants';
import IntegrationsTable from '~/integrations/index/components/integrations_table.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

import { mockActiveIntegrations, mockInactiveIntegrations } from '../mock_data';

describe('IntegrationsTable', () => {
  let wrapper;

  const findTable = () => wrapper.findComponent(GlTable);

  const createComponent = (propsData = {}, flagIsOn = false) => {
    wrapper = mount(IntegrationsTable, {
      propsData: {
        integrations: mockActiveIntegrations,
        ...propsData,
      },
      provide: {
        glFeatures: {
          integrationSlackAppNotifications: flagIsOn,
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each([true, false])('when `showUpdatedAt` is %p', (showUpdatedAt) => {
    beforeEach(() => {
      createComponent({ showUpdatedAt });
    });

    it(`${showUpdatedAt ? 'renders' : 'does not render'} content in "Last updated" column`, () => {
      const headers = findTable().findAll('th');
      expect(headers.wrappers.some((header) => header.text() === 'Last updated')).toBe(
        showUpdatedAt,
      );
      expect(wrapper.findComponent(TimeAgoTooltip).exists()).toBe(showUpdatedAt);
    });
  });

  describe.each`
    scenario                          | integrations                     | shouldRenderActiveIcon
    ${'when integration is active'}   | ${[mockActiveIntegrations[0]]}   | ${true}
    ${'when integration is inactive'} | ${[mockInactiveIntegrations[0]]} | ${false}
  `('$scenario', ({ shouldRenderActiveIcon, integrations }) => {
    beforeEach(() => {
      createComponent({ integrations });
    });

    it(`${shouldRenderActiveIcon ? 'renders' : 'does not render'} icon in first column`, () => {
      expect(findTable().findComponent(GlIcon).exists()).toBe(shouldRenderActiveIcon);
    });
  });

  describe('integrations filtering', () => {
    const slackActive = {
      ...mockActiveIntegrations[0],
      name: INTEGRATION_TYPE_SLACK,
      title: 'Slack',
    };
    const slackInactive = {
      ...mockInactiveIntegrations[0],
      name: INTEGRATION_TYPE_SLACK,
      title: 'Slack',
    };

    describe.each`
      desc                                         | flagIsOn | integrations                                                               | expectedIntegrations
      ${'only active'}                             | ${false} | ${mockActiveIntegrations}                                                  | ${mockActiveIntegrations}
      ${'only active'}                             | ${true}  | ${mockActiveIntegrations}                                                  | ${mockActiveIntegrations}
      ${'only inactive'}                           | ${true}  | ${mockInactiveIntegrations}                                                | ${mockInactiveIntegrations}
      ${'only inactive'}                           | ${false} | ${mockInactiveIntegrations}                                                | ${mockInactiveIntegrations}
      ${'active and inactive'}                     | ${true}  | ${[...mockActiveIntegrations, ...mockInactiveIntegrations]}                | ${[...mockActiveIntegrations, ...mockInactiveIntegrations]}
      ${'active and inactive'}                     | ${false} | ${[...mockActiveIntegrations, ...mockInactiveIntegrations]}                | ${[...mockActiveIntegrations, ...mockInactiveIntegrations]}
      ${'Slack active with active'}                | ${false} | ${[slackActive, ...mockActiveIntegrations]}                                | ${[slackActive, ...mockActiveIntegrations]}
      ${'Slack active with active'}                | ${true}  | ${[slackActive, ...mockActiveIntegrations]}                                | ${[slackActive, ...mockActiveIntegrations]}
      ${'Slack active with inactive'}              | ${false} | ${[slackActive, ...mockInactiveIntegrations]}                              | ${[slackActive, ...mockInactiveIntegrations]}
      ${'Slack active with inactive'}              | ${true}  | ${[slackActive, ...mockInactiveIntegrations]}                              | ${[slackActive, ...mockInactiveIntegrations]}
      ${'Slack inactive with active'}              | ${false} | ${[slackInactive, ...mockActiveIntegrations]}                              | ${[slackInactive, ...mockActiveIntegrations]}
      ${'Slack inactive with active'}              | ${true}  | ${[slackInactive, ...mockActiveIntegrations]}                              | ${mockActiveIntegrations}
      ${'Slack inactive with inactive'}            | ${false} | ${[slackInactive, ...mockInactiveIntegrations]}                            | ${[slackInactive, ...mockInactiveIntegrations]}
      ${'Slack inactive with inactive'}            | ${true}  | ${[slackInactive, ...mockInactiveIntegrations]}                            | ${mockInactiveIntegrations}
      ${'Slack active with active and inactive'}   | ${true}  | ${[slackActive, ...mockActiveIntegrations, ...mockInactiveIntegrations]}   | ${[slackActive, ...mockActiveIntegrations, ...mockInactiveIntegrations]}
      ${'Slack active with active and inactive'}   | ${false} | ${[slackActive, ...mockActiveIntegrations, ...mockInactiveIntegrations]}   | ${[slackActive, ...mockActiveIntegrations, ...mockInactiveIntegrations]}
      ${'Slack inactive with active and inactive'} | ${true}  | ${[slackInactive, ...mockActiveIntegrations, ...mockInactiveIntegrations]} | ${[...mockActiveIntegrations, ...mockInactiveIntegrations]}
      ${'Slack inactive with active and inactive'} | ${false} | ${[slackInactive, ...mockActiveIntegrations, ...mockInactiveIntegrations]} | ${[slackInactive, ...mockActiveIntegrations, ...mockInactiveIntegrations]}
    `('when $desc and flag "$flagIsOn"', ({ flagIsOn, integrations, expectedIntegrations }) => {
      beforeEach(() => {
        createComponent({ integrations }, flagIsOn);
      });

      it('renders correctly', () => {
        const links = wrapper.findAllComponents(GlLink);
        expect(links).toHaveLength(expectedIntegrations.length);
        expectedIntegrations.forEach((integration, index) => {
          expect(links.at(index).text()).toBe(integration.title);
        });
      });
    });
  });
});
