import { GlTable, GlLink, GlBadge, GlButton } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import IntegrationsTable from '~/integrations/index/components/integrations_table.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

import { mockActiveIntegrations, mockInactiveIntegrations } from '../mock_data';

describe('IntegrationsTable', () => {
  let wrapper;

  const findTable = () => wrapper.findComponent(GlTable);
  const findDeprecationBadge = () => wrapper.findComponent(GlBadge);
  const findDeprecationHelpLink = () => wrapper.findByTestId('sscDeprecationLink');
  const findDeprecationSprint = () => wrapper.findByTestId('deprecation-message');

  const createComponent = (propsData = {}, glFeatures = {}, isAdmin = false) => {
    wrapper = mountExtended(IntegrationsTable, {
      propsData: {
        integrations: mockActiveIntegrations,
        ...propsData,
      },
      provide: {
        glFeatures,
        isAdmin,
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
    scenario                          | integrations                     | expectActiveIcon
    ${'when integration is active'}   | ${[mockActiveIntegrations[0]]}   | ${true}
    ${'when integration is inactive'} | ${[mockInactiveIntegrations[0]]} | ${false}
  `('$scenario', ({ expectActiveIcon, integrations }) => {
    beforeEach(() => {
      createComponent({ integrations });
    });

    it(`${expectActiveIcon ? 'renders' : 'does not render'} icon in first column`, () => {
      expect(findTable().find('[data-testid="integration-active-icon"]').exists()).toBe(
        expectActiveIcon,
      );
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
    const findEditButton = () => findTable().findComponent(GlButton);

    beforeEach(() => {
      createComponent({ integrations: mockInactiveIntegrations, inactive });
    });

    it(`${inactive ? 'does not render' : 'render'} updated_at field`, () => {
      expect(findTable().find('[aria-label="Updated At"]').exists()).toBe(!inactive);
    });

    if (inactive) {
      it('renders Edit button as "Add integration"', () => {
        expect(findEditButton().props('icon')).toBe('plus');
        expect(findEditButton().text()).toBe('Add');
      });
    } else {
      it('renders Edit button as "Configure"', () => {
        expect(findEditButton().props('icon')).toBe('settings');
      });
    }
  });

  describe('Slack slash command deprecation warning', () => {
    const slackSlashIntegration = {
      active: true,
      configured: true,
      title: 'Slack slash command',
      description: 'Perform common operations in Slack.',
      updated_at: '2021-03-18T00:27:09.634Z',
      edit_path:
        '/gitlab-qa-sandbox-group/project_with_jenkins_6a55a67c-57c6ed0597c9319a/-/services/slack_slash_commands/edit',
      name: 'slack_slash_commands',
    };

    it('does not render when there is no active slack slash integration', () => {
      createComponent();
      expect(findDeprecationBadge().exists()).toBe(false);
    });

    describe('when there is an active slack slash integration', () => {
      it('renders when user is not admin', () => {
        createComponent({ integrations: [slackSlashIntegration] });
        expect(findDeprecationBadge().exists()).toBe(true);
        expect(findDeprecationBadge().text()).toContain('Deprecated');
        expect(findDeprecationSprint().text()).toContain(
          'This integration is deprecated and replaced with the',
        );
        const link = findDeprecationHelpLink();
        expect(link.text()).toBe('GitLab for Slack app');
        expect(link.attributes('href')).toBe(
          '/help/user/project/integrations/gitlab_slack_application',
        );
        expect(findDeprecationSprint().text()).toContain(
          'Contact your GitLab administrator for help.',
        );
      });
    });

    it('renders when user is admin', () => {
      createComponent({ integrations: [slackSlashIntegration] }, {}, true);
      expect(findDeprecationBadge().exists()).toBe(true);
      expect(findDeprecationSprint().text()).toContain(
        'This integration is deprecated. Install the',
      );
      const link = findDeprecationHelpLink();
      expect(link.text()).toBe('GitLab for Slack app');
      expect(link.attributes('href')).toBe('/help/administration/settings/slack_app');
    });
  });
});
