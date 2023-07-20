import { GlTable, GlIcon, GlLink } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import IntegrationsTable from '~/integrations/index/components/integrations_table.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

import { mockActiveIntegrations, mockInactiveIntegrations } from '../mock_data';

describe('IntegrationsTable', () => {
  let wrapper;

  const findTable = () => wrapper.findComponent(GlTable);

  const createComponent = (propsData = {}, glFeatures = {}) => {
    wrapper = mount(IntegrationsTable, {
      propsData: {
        integrations: mockActiveIntegrations,
        ...propsData,
      },
      provide: {
        glFeatures,
      },
    });
  };

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

  describe.each([true, false])(
    'when `remove_monitor_metrics` flag  is %p',
    (removeMonitorMetrics) => {
      beforeEach(() => {
        createComponent({ integrations: [mockInactiveIntegrations[3]] }, { removeMonitorMetrics });
      });

      it(`${removeMonitorMetrics ? 'does not render' : 'renders'} prometheus integration`, () => {
        expect(findTable().findComponent(GlLink).exists()).toBe(!removeMonitorMetrics);
      });
    },
  );

  describe('when no integrations are received', () => {
    beforeEach(() => {
      createComponent({ integrations: [] });
    });

    it('does not display fields in the table', () => {
      expect(findTable().findAll('th')).toHaveLength(0);
    });
  });

  describe.each([true, false])('when integrations inactive property is %p', (inactive) => {
    beforeEach(() => {
      createComponent({ integrations: [mockInactiveIntegrations], inactive });
    });

    it(`${inactive ? 'does not render' : 'render'} updated_at field`, () => {
      expect(findTable().find('[aria-label="Updated At"]').exists()).toBe(!inactive);
    });
  });
});
