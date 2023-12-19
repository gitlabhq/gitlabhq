import { GlCollapse, GlButton, GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import IntegrationStatus from '~/clusters/agents/components/integration_status.vue';
import AgentIntegrationStatusRow from '~/clusters/agents/components/agent_integration_status_row.vue';
import { ACTIVE_CONNECTION_TIME } from '~/clusters_list/constants';
import {
  INTEGRATION_STATUS_VALID_TOKEN,
  INTEGRATION_STATUS_NO_TOKEN,
  INTEGRATION_STATUS_RESTRICTED_CI_CD,
} from '~/clusters/agents/constants';

const connectedTimeNow = new Date();
const connectedTimeInactive = new Date(connectedTimeNow.getTime() - ACTIVE_CONNECTION_TIME);

describe('IntegrationStatus', () => {
  let wrapper;

  const createWrapper = (tokens = []) => {
    wrapper = shallowMountExtended(IntegrationStatus, {
      propsData: { tokens },
    });
  };

  const findCollapseButton = () => wrapper.findComponent(GlButton);
  const findCollapse = () => wrapper.findComponent(GlCollapse);
  const findStatusIcon = () => wrapper.findComponent(GlIcon);
  const findAgentStatus = () => wrapper.findByTestId('agent-status');
  const findAgentIntegrationStatusRows = () => wrapper.findAllComponents(AgentIntegrationStatusRow);

  it.each`
    lastUsedAt               | status               | iconName
    ${null}                  | ${'Never connected'} | ${'status-neutral'}
    ${connectedTimeNow}      | ${'Connected'}       | ${'status-success'}
    ${connectedTimeInactive} | ${'Not connected'}   | ${'status-alert'}
  `(
    'displays correct text and icon when agent connection status is "$status"',
    ({ lastUsedAt, status, iconName }) => {
      const tokens = [{ lastUsedAt }];
      createWrapper(tokens);

      expect(findStatusIcon().props('name')).toBe(iconName);
      expect(findAgentStatus().text()).toBe(status);
    },
  );

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('shows the collapse toggle button', () => {
      expect(findCollapseButton().text()).toBe(wrapper.vm.$options.i18n.title);
      expect(findCollapseButton().attributes()).toMatchObject({
        variant: 'link',
        icon: 'chevron-right',
        size: 'small',
      });
    });

    it('sets collapse component as invisible by default', () => {
      expect(findCollapse().props('visible')).toBe(false);
    });
  });

  describe('when user clicks collapse toggle', () => {
    beforeEach(() => {
      createWrapper();
      findCollapseButton().vm.$emit('click');
    });

    it('changes the collapse button icon', () => {
      expect(findCollapseButton().props('icon')).toBe('chevron-down');
    });

    it('sets collapse component as visible', () => {
      expect(findCollapse().props('visible')).toBe(true);
    });
  });

  describe('integration status details', () => {
    it.each`
      agentStatus   | tokens                                     | integrationStatuses
      ${'active'}   | ${[{ lastUsedAt: connectedTimeNow }]}      | ${[INTEGRATION_STATUS_VALID_TOKEN, INTEGRATION_STATUS_RESTRICTED_CI_CD]}
      ${'inactive'} | ${[{ lastUsedAt: connectedTimeInactive }]} | ${[INTEGRATION_STATUS_RESTRICTED_CI_CD]}
      ${'inactive'} | ${[]}                                      | ${[INTEGRATION_STATUS_NO_TOKEN, INTEGRATION_STATUS_RESTRICTED_CI_CD]}
      ${'unused'}   | ${[{ lastUsedAt: null }]}                  | ${[INTEGRATION_STATUS_RESTRICTED_CI_CD]}
      ${'unused'}   | ${[]}                                      | ${[INTEGRATION_STATUS_NO_TOKEN, INTEGRATION_STATUS_RESTRICTED_CI_CD]}
    `(
      'displays AgentIntegrationStatusRow component with correct properties when agent status is $agentStatus and agent has $tokens.length tokens',
      ({ tokens, integrationStatuses }) => {
        createWrapper(tokens);

        expect(findAgentIntegrationStatusRows().length).toBe(integrationStatuses.length);

        integrationStatuses.forEach((integrationStatus, index) => {
          expect(findAgentIntegrationStatusRows().at(index).props()).toMatchObject({
            icon: integrationStatus.icon,
            iconClass: integrationStatus.iconClass,
            text: integrationStatus.text,
            helpUrl: integrationStatus.helpUrl || null,
            featureName: integrationStatus.featureName || null,
          });
        });
      },
    );
  });
});
