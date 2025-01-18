import { nextTick } from 'vue';
import { GlTabs, GlTab, GlAlert, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking } from 'helpers/tracking_helper';
import ClustersMainView from '~/clusters_list/components/clusters_main_view.vue';
import InstallAgentModal from '~/clusters_list/components/install_agent_modal.vue';
import {
  AGENT,
  CERTIFICATE_BASED,
  AGENT_TAB,
  CLUSTERS_TABS,
  CERTIFICATE_TAB,
  EVENT_LABEL_TABS,
  EVENT_ACTIONS_CHANGE,
} from '~/clusters_list/constants';

const defaultBranchName = 'default-branch';

describe('ClustersMainViewComponent', () => {
  let wrapper;
  let trackingSpy;

  const propsData = {
    defaultBranchName,
  };

  const defaultProvide = {
    certificateBasedClustersEnabled: true,
    displayClusterAgents: true,
  };

  const createWrapper = (extendedProvide = {}) => {
    wrapper = shallowMountExtended(ClustersMainView, {
      propsData,
      provide: {
        ...defaultProvide,
        ...extendedProvide,
      },
      stubs: { GlSprintf },
    });
  };

  const findTabs = () => wrapper.findComponent(GlTabs);
  const findAllTabs = () => wrapper.findAllComponents(GlTab);
  const findGlTabAtIndex = (index) => findAllTabs().at(index);
  const findComponent = () => wrapper.findByTestId('clusters-tab-component');
  const findModal = () => wrapper.findComponent(InstallAgentModal);
  const findAlert = () => wrapper.findComponent(GlAlert);

  describe('when the certificate based clusters are enabled', () => {
    describe('when on project level', () => {
      beforeEach(() => {
        createWrapper({ displayClusterAgents: true });
        trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      });

      it('renders `GlTabs` with `syncActiveTabWithQueryParams` and `queryParamName` props set', () => {
        expect(findTabs().exists()).toBe(true);
        expect(findTabs().props('syncActiveTabWithQueryParams')).toBe(true);
      });

      it('renders correct number of tabs', () => {
        expect(findAllTabs()).toHaveLength(CLUSTERS_TABS.length);
      });

      describe('tabs', () => {
        it.each`
          tabTitle         | queryParamValue      | lineNumber
          ${'All'}         | ${'all'}             | ${0}
          ${'Agent'}       | ${AGENT}             | ${1}
          ${'Certificate'} | ${CERTIFICATE_BASED} | ${2}
        `(
          'renders correct tab title and query param value',
          ({ tabTitle, queryParamValue, lineNumber }) => {
            expect(findGlTabAtIndex(lineNumber).attributes('title')).toBe(tabTitle);
            expect(findGlTabAtIndex(lineNumber).props('queryParamValue')).toBe(queryParamValue);
          },
        );
      });

      describe.each`
        tab    | tabName
        ${'1'} | ${AGENT}
        ${'2'} | ${CERTIFICATE_BASED}
      `(
        'when the child component emits the tab change event for $tabName tab',
        ({ tab, tabName }) => {
          beforeEach(() => {
            findComponent().vm.$emit('changeTab', tabName);
          });

          it(`changes the tab value to ${tab}`, () => {
            expect(findTabs().attributes('value')).toBe(tab);
          });
        },
      );

      describe.each`
        tab  | tabName
        ${1} | ${AGENT}
        ${2} | ${CERTIFICATE_BASED}
      `('when the active tab is $tabName', ({ tab, tabName }) => {
        beforeEach(() => {
          findTabs().vm.$emit('input', tab);
        });

        it('passes child-component param to the component', () => {
          expect(findComponent().props('defaultBranchName')).toBe(defaultBranchName);
        });

        it('passes kasDisabled param if received from the component to the modal', async () => {
          findComponent().vm.$emit('kasDisabled', true);
          await nextTick();

          expect(findModal().props('kasDisabled')).toBe(true);
        });

        it(`sends the correct tracking event with the property '${tabName}'`, () => {
          expect(trackingSpy).toHaveBeenCalledWith(undefined, EVENT_ACTIONS_CHANGE, {
            label: EVENT_LABEL_TABS,
            property: tabName,
          });
        });
      });
    });

    describe('when an agent is registered from the config table', () => {
      const modalSpy = jest.fn();

      beforeEach(() => {
        createWrapper({ displayClusterAgents: true });
        findModal().vm.showModalForAgent = modalSpy;
        findComponent().vm.$emit('registerAgent', 'new-agent-name');
      });

      it('calls showModalForAgent when registerAgent is received from the component', () => {
        expect(modalSpy).toHaveBeenCalledWith('new-agent-name');
      });

      it('should not render a success alert', async () => {
        findModal().vm.$emit('clusterAgentCreated', 'new-agent-name');
        await nextTick();

        expect(findAlert().exists()).toBe(false);
      });
    });

    describe('when a new agent got registered', () => {
      const newAgentName = 'my-new-agent';

      beforeEach(async () => {
        createWrapper();
        findModal().vm.$emit('clusterAgentCreated', newAgentName);
        await nextTick();
      });

      it('should render a success alert', () => {
        expect(findAlert().attributes('variant')).toBe('success');
      });

      it("should provide agent's name to the alert title", () => {
        expect(findAlert().props('title')).toBe(`${newAgentName} successfully created`);
      });

      it('should provide message about agent configuration', () => {
        expect(findAlert().text()).toBe(
          `Optionally, for additional configuration settings, a configuration file can be created in the repository. You can do so within the default branch by creating the file at: .gitlab/agents/${newAgentName}/config.yaml`,
        );
      });

      it('should hide alert on dismiss', async () => {
        findAlert().vm.$emit('dismiss');
        await nextTick();

        expect(findAlert().exists()).toBe(false);
      });
    });

    describe('when on group or admin level', () => {
      beforeEach(() => {
        createWrapper({ displayClusterAgents: false });
      });

      it('renders correct number of tabs', () => {
        expect(findAllTabs()).toHaveLength(1);
      });

      it('renders correct tab title', () => {
        expect(findGlTabAtIndex(0).attributes('title')).toBe(CERTIFICATE_TAB.title);
      });
    });

    describe('when the certificate based clusters not enabled', () => {
      beforeEach(() => {
        createWrapper({ certificateBasedClustersEnabled: false });
      });

      it('displays only the Agent tab', () => {
        expect(findAllTabs()).toHaveLength(1);
        const agentTab = findGlTabAtIndex(0);

        expect(agentTab.props()).toMatchObject({
          queryParamValue: AGENT_TAB.queryParamValue,
          titleLinkClass: '',
        });
        expect(agentTab.attributes()).toMatchObject({
          title: AGENT_TAB.title,
        });
      });
    });
  });
});
