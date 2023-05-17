import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { sprintf } from '~/locale';
import HistoryItem from '~/vue_shared/components/registry/history_item.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import ActivityHistoryItem from '~/clusters/agents/components/activity_history_item.vue';
import { EVENT_DETAILS, DEFAULT_ICON } from '~/clusters/agents/constants';
import { mockAgentHistoryActivityItems } from '../../mock_data';

const agentName = 'cluster-agent';

describe('ActivityHistoryItem', () => {
  let wrapper;

  const createWrapper = ({ event = {} }) => {
    wrapper = shallowMount(ActivityHistoryItem, {
      propsData: { event },
      stubs: {
        HistoryItem,
        GlSprintf,
      },
    });
  };

  const findHistoryItem = () => wrapper.findComponent(HistoryItem);
  const findTimeAgo = () => wrapper.findComponent(TimeAgoTooltip);

  describe.each`
    kind                    | icon                                              | title                                                                   | lineNumber
    ${'token_created'}      | ${EVENT_DETAILS.token_created.eventTypeIcon}      | ${sprintf(EVENT_DETAILS.token_created.title, { tokenName: agentName })} | ${0}
    ${'token_revoked'}      | ${EVENT_DETAILS.token_revoked.eventTypeIcon}      | ${sprintf(EVENT_DETAILS.token_revoked.title, { tokenName: agentName })} | ${1}
    ${'agent_connected'}    | ${EVENT_DETAILS.agent_connected.eventTypeIcon}    | ${sprintf(EVENT_DETAILS.agent_connected.title, { titleIcon: '' })}      | ${2}
    ${'agent_disconnected'} | ${EVENT_DETAILS.agent_disconnected.eventTypeIcon} | ${sprintf(EVENT_DETAILS.agent_disconnected.title, { titleIcon: '' })}   | ${3}
    ${'agent_connected'}    | ${EVENT_DETAILS.agent_connected.eventTypeIcon}    | ${sprintf(EVENT_DETAILS.agent_connected.title, { titleIcon: '' })}      | ${4}
    ${'unknown_agent'}      | ${DEFAULT_ICON}                                   | ${'unknown_agent Event occurred'}                                       | ${5}
  `('when the event type is $kind event', ({ icon, title, lineNumber }) => {
    beforeEach(() => {
      const event = mockAgentHistoryActivityItems[lineNumber];
      createWrapper({ event });
    });
    it('renders the correct icon', () => {
      expect(findHistoryItem().props('icon')).toBe(icon);
    });
    it('renders the correct title', () => {
      expect(findHistoryItem().text()).toContain(title);
    });
    it('renders the correct time-ago tooltip', () => {
      const activityEvents = mockAgentHistoryActivityItems;
      expect(findTimeAgo().props('time')).toBe(activityEvents[lineNumber].recordedAt);
    });
  });
});
