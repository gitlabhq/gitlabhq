import {
  GlButton,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlTooltip,
  GlButtonGroup,
} from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ClustersActions from '~/clusters_list/components/clusters_actions.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { INSTALL_AGENT_MODAL_ID, CLUSTERS_ACTIONS } from '~/clusters_list/constants';

describe('ClustersActionsComponent', () => {
  let wrapper;

  const addClusterPath = 'path/to/connect/existing/cluster';
  const newClusterDocsPath = 'path/to/create/new/cluster';

  const defaultProvide = {
    addClusterPath,
    newClusterDocsPath,
    canAddCluster: true,
    displayClusterAgents: true,
    certificateBasedClustersEnabled: true,
  };

  const findButtonGroup = () => wrapper.findComponent(GlButtonGroup);
  const findButton = () => wrapper.findComponent(GlButton);
  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDropdownItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findTooltip = () => wrapper.findComponent(GlTooltip);
  const findDropdownItemIds = () =>
    findDropdownItems().wrappers.map((x) => x.find('a').attributes('data-testid'));
  const findDropdownItemTexts = () => findDropdownItems().wrappers.map((x) => x.text());
  const findNewClusterDocsLink = () => wrapper.findByTestId('create-cluster-link');
  const findConnectClusterLink = () => wrapper.findByTestId('connect-cluster-link');

  const createWrapper = (provideData = {}) => {
    wrapper = mountExtended(ClustersActions, {
      provide: {
        ...defaultProvide,
        ...provideData,
      },
      stubs: {
        GlDisclosureDropdown,
        GlDisclosureDropdownItem,
      },
      directives: {
        GlModalDirective: createMockDirective('gl-modal-directive'),
      },
    });
  };

  beforeEach(() => {
    createWrapper();
  });

  describe('when the certificate based clusters are enabled', () => {
    it('renders actions menu button group with dropdown', () => {
      expect(findButtonGroup().exists()).toBe(true);
      expect(findButton().exists()).toBe(true);
      expect(findDropdown().exists()).toBe(true);
    });

    it("doesn't show the tooltip", () => {
      expect(findTooltip().exists()).toBe(false);
    });

    describe('when on project level', () => {
      it(`displays default action as ${CLUSTERS_ACTIONS.connectWithAgent}`, () => {
        expect(findButton().text()).toBe(CLUSTERS_ACTIONS.connectWithAgent);
      });

      it('renders correct modal id for the default action', () => {
        const binding = getBinding(findButton().element, 'gl-modal-directive');

        expect(binding.value).toBe(INSTALL_AGENT_MODAL_ID);
      });

      it('renders a dropdown with 2 actions items', () => {
        expect(findDropdownItemIds()).toEqual(['create-cluster-link', 'connect-cluster-link']);
      });

      it('renders correct texts for the dropdown items', () => {
        expect(findDropdownItemTexts()).toEqual([
          CLUSTERS_ACTIONS.createCluster,
          CLUSTERS_ACTIONS.connectClusterCertificate,
        ]);
      });

      it('renders correct href attributes for the links', () => {
        expect(findNewClusterDocsLink().attributes('href')).toBe(newClusterDocsPath);
        expect(findConnectClusterLink().attributes('href')).toBe(addClusterPath);
      });

      describe('when user cannot add clusters', () => {
        beforeEach(() => {
          createWrapper({ canAddCluster: false });
        });

        it('disables dropdown', () => {
          expect(findDropdown().props('disabled')).toBe(true);
          expect(findButton().props('disabled')).toBe(true);
        });

        it('shows tooltip explaining why dropdown is disabled', () => {
          expect(findTooltip().attributes('title')).toBe(CLUSTERS_ACTIONS.actionsDisabledHint);
        });

        it('does not bind split dropdown button', () => {
          const binding = getBinding(findButton().element, 'gl-modal-directive');

          expect(binding.value).toBe(false);
        });
      });
    });

    describe('when on group or admin level', () => {
      beforeEach(() => {
        createWrapper({ displayClusterAgents: false });
      });

      it("doesn't render a dropdown", () => {
        expect(findDropdown().exists()).toBe(false);
      });

      it('render an action button', () => {
        expect(findButton().exists()).toBe(true);
      });

      it(`displays default action as ${CLUSTERS_ACTIONS.connectClusterDeprecated}`, () => {
        expect(findButton().text()).toBe(CLUSTERS_ACTIONS.connectClusterDeprecated);
      });

      it('renders correct href attribute for the button', () => {
        expect(findButton().attributes('href')).toBe(addClusterPath);
      });

      describe('when user cannot add clusters', () => {
        beforeEach(() => {
          createWrapper({ displayClusterAgents: false, canAddCluster: false });
        });

        it('disables action button', () => {
          expect(findButton().props('disabled')).toBe(true);
        });

        it('shows tooltip explaining why dropdown is disabled', () => {
          expect(findTooltip().attributes('title')).toBe(CLUSTERS_ACTIONS.actionsDisabledHint);
        });
      });
    });
  });

  describe('when the certificate based clusters not enabled', () => {
    beforeEach(() => {
      createWrapper({ certificateBasedClustersEnabled: false });
    });

    it(`displays default action as ${CLUSTERS_ACTIONS.connectCluster}`, () => {
      expect(findButton().text()).toBe(CLUSTERS_ACTIONS.connectCluster);
    });

    it('renders correct modal id for the default action', () => {
      const binding = getBinding(findButton().element, 'gl-modal-directive');

      expect(binding.value).toBe(INSTALL_AGENT_MODAL_ID);
    });

    it('renders a dropdown with 1 action item', () => {
      expect(findDropdownItemIds()).toEqual(['create-cluster-link']);
    });

    it('renders correct text for the dropdown item', () => {
      expect(findDropdownItemTexts()).toEqual([CLUSTERS_ACTIONS.createCluster]);
    });

    it('renders correct href attributes for the links', () => {
      expect(findNewClusterDocsLink().attributes('href')).toBe(newClusterDocsPath);
    });
  });
});
