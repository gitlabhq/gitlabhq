import { GlLink, GlIcon } from '@gitlab/ui';
import { sprintf } from '~/locale';
import AgentTable from '~/clusters_list/components/agent_table.vue';
import DeleteAgentButton from '~/clusters_list/components/delete_agent_button.vue';
import { I18N_AGENT_TABLE } from '~/clusters_list/constants';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { clusterAgents, connectedTimeNow, connectedTimeInactive } from './mock_data';

const provideData = {
  gitlabVersion: '14.8',
};
const propsData = {
  agents: clusterAgents,
};

const DeleteAgentButtonStub = stubComponent(DeleteAgentButton, {
  template: `<div></div>`,
});

const outdatedTitle = I18N_AGENT_TABLE.versionOutdatedTitle;
const mismatchTitle = I18N_AGENT_TABLE.versionMismatchTitle;
const mismatchOutdatedTitle = I18N_AGENT_TABLE.versionMismatchOutdatedTitle;
const outdatedText = sprintf(I18N_AGENT_TABLE.versionOutdatedText, {
  version: provideData.gitlabVersion,
});
const mismatchText = I18N_AGENT_TABLE.versionMismatchText;

describe('AgentTable', () => {
  let wrapper;

  const findAgentLink = (at) => wrapper.findAllByTestId('cluster-agent-name-link').at(at);
  const findStatusIcon = (at) => wrapper.findAllComponents(GlIcon).at(at);
  const findStatusText = (at) => wrapper.findAllByTestId('cluster-agent-connection-status').at(at);
  const findLastContactText = (at) => wrapper.findAllByTestId('cluster-agent-last-contact').at(at);
  const findVersionText = (at) => wrapper.findAllByTestId('cluster-agent-version').at(at);
  const findConfiguration = (at) =>
    wrapper.findAllByTestId('cluster-agent-configuration-link').at(at);
  const findDeleteAgentButton = () => wrapper.findAllComponents(DeleteAgentButton);

  beforeEach(() => {
    wrapper = mountExtended(AgentTable, {
      propsData,
      provide: provideData,
      stubs: {
        DeleteAgentButton: DeleteAgentButtonStub,
      },
    });
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  describe('agent table', () => {
    it.each`
      agentName    | link          | lineNumber
      ${'agent-1'} | ${'/agent-1'} | ${0}
      ${'agent-2'} | ${'/agent-2'} | ${1}
    `('displays agent link for $agentName', ({ agentName, link, lineNumber }) => {
      expect(findAgentLink(lineNumber).text()).toBe(agentName);
      expect(findAgentLink(lineNumber).attributes('href')).toBe(link);
    });

    it.each`
      status               | iconName               | lineNumber
      ${'Never connected'} | ${'status-neutral'}    | ${0}
      ${'Connected'}       | ${'status-success'}    | ${1}
      ${'Not connected'}   | ${'severity-critical'} | ${2}
    `(
      'displays agent connection status as "$status" at line $lineNumber',
      ({ status, iconName, lineNumber }) => {
        expect(findStatusText(lineNumber).text()).toBe(status);
        expect(findStatusIcon(lineNumber).props('name')).toBe(iconName);
      },
    );

    it.each`
      lastContact                                                  | lineNumber
      ${'Never'}                                                   | ${0}
      ${timeagoMixin.methods.timeFormatted(connectedTimeNow)}      | ${1}
      ${timeagoMixin.methods.timeFormatted(connectedTimeInactive)} | ${2}
    `(
      'displays agent last contact time as "$lastContact" at line $lineNumber',
      ({ lastContact, lineNumber }) => {
        expect(findLastContactText(lineNumber).text()).toBe(lastContact);
      },
    );

    describe.each`
      agent        | version   | podsNumber | versionMismatch | versionOutdated | title                    | texts                           | lineNumber
      ${'agent-1'} | ${''}     | ${1}       | ${false}        | ${false}        | ${''}                    | ${''}                           | ${0}
      ${'agent-2'} | ${'14.8'} | ${2}       | ${false}        | ${false}        | ${''}                    | ${''}                           | ${1}
      ${'agent-3'} | ${'14.5'} | ${1}       | ${false}        | ${true}         | ${outdatedTitle}         | ${[outdatedText]}               | ${2}
      ${'agent-4'} | ${'14.7'} | ${2}       | ${true}         | ${false}        | ${mismatchTitle}         | ${[mismatchText]}               | ${3}
      ${'agent-5'} | ${'14.3'} | ${2}       | ${true}         | ${true}         | ${mismatchOutdatedTitle} | ${[mismatchText, outdatedText]} | ${4}
    `(
      'agent version column at line $lineNumber',
      ({
        agent,
        version,
        podsNumber,
        versionMismatch,
        versionOutdated,
        title,
        texts,
        lineNumber,
      }) => {
        const findIcon = () => findVersionText(lineNumber).find(GlIcon);
        const findPopover = () => wrapper.findByTestId(`popover-${agent}`);
        const versionWarning = versionMismatch || versionOutdated;

        it('shows the correct agent version', () => {
          expect(findVersionText(lineNumber).text()).toBe(version);
        });

        if (versionWarning) {
          it(`shows a warning icon when agent versions mismatch is ${versionMismatch} and outdated is ${versionOutdated} and the number of pods is ${podsNumber}`, () => {
            expect(findIcon().props('name')).toBe('warning');
          });

          it(`renders correct title for the popover when agent versions mismatch is ${versionMismatch} and outdated is ${versionOutdated}`, () => {
            expect(findPopover().props('title')).toBe(title);
          });

          it(`renders correct text for the popover when agent versions mismatch is ${versionMismatch} and outdated is ${versionOutdated}`, () => {
            texts.forEach((text) => {
              expect(findPopover().text()).toContain(text);
            });
          });
        } else {
          it(`doesn't show a warning icon with a popover when agent versions mismatch is ${versionMismatch} and outdated is ${versionOutdated} and the number of pods is ${podsNumber}`, () => {
            expect(findIcon().exists()).toBe(false);
            expect(findPopover().exists()).toBe(false);
          });
        }
      },
    );

    it.each`
      agentPath                   | hasLink  | lineNumber
      ${'.gitlab/agents/agent-1'} | ${true}  | ${0}
      ${'.gitlab/agents/agent-2'} | ${false} | ${1}
    `(
      'displays config file path as "$agentPath" at line $lineNumber',
      ({ agentPath, hasLink, lineNumber }) => {
        const findLink = findConfiguration(lineNumber).find(GlLink);

        expect(findLink.exists()).toBe(hasLink);
        expect(findConfiguration(lineNumber).text()).toBe(agentPath);
      },
    );

    it('displays actions menu for each agent', () => {
      expect(findDeleteAgentButton()).toHaveLength(5);
    });
  });
});
