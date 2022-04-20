import { GlDropdown, GlDropdownItem, GlTooltip } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ClustersActions from '~/clusters_list/components/clusters_actions.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { INSTALL_AGENT_MODAL_ID, CLUSTERS_ACTIONS } from '~/clusters_list/constants';

describe('ClustersActionsComponent', () => {
  let wrapper;

  const newClusterPath = 'path/to/add/cluster';
  const addClusterPath = 'path/to/connect/existing/cluster';
  const newClusterDocsPath = 'path/to/create/new/cluster';

  const defaultProvide = {
    newClusterPath,
    addClusterPath,
    newClusterDocsPath,
    canAddCluster: true,
    displayClusterAgents: true,
    certificateBasedClustersEnabled: true,
  };

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findTooltip = () => wrapper.findComponent(GlTooltip);
  const findDropdownItemIds = () =>
    findDropdownItems().wrappers.map((x) => x.attributes('data-testid'));
  const findDropdownItemTexts = () => findDropdownItems().wrappers.map((x) => x.text());
  const findNewClusterLink = () => wrapper.findByTestId('new-cluster-link');
  const findNewClusterDocsLink = () => wrapper.findByTestId('create-cluster-link');
  const findConnectClusterLink = () => wrapper.findByTestId('connect-cluster-link');

  const createWrapper = (provideData = {}) => {
    wrapper = shallowMountExtended(ClustersActions, {
      provide: {
        ...defaultProvide,
        ...provideData,
      },
      directives: {
        GlModalDirective: createMockDirective(),
      },
    });
  };

  beforeEach(() => {
    createWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
  });
  describe('when the certificate based clusters are enabled', () => {
    it('renders actions menu', () => {
      expect(findDropdown().exists()).toBe(true);
    });

    it('shows split button in dropdown', () => {
      expect(findDropdown().props('split')).toBe(true);
    });

    it("doesn't show the tooltip", () => {
      expect(findTooltip().exists()).toBe(false);
    });

    describe('when user cannot add clusters', () => {
      beforeEach(() => {
        createWrapper({ canAddCluster: false });
      });

      it('disables dropdown', () => {
        expect(findDropdown().props('disabled')).toBe(true);
      });

      it('shows tooltip explaining why dropdown is disabled', () => {
        expect(findTooltip().attributes('title')).toBe(CLUSTERS_ACTIONS.dropdownDisabledHint);
      });

      it('does not bind split dropdown button', () => {
        const binding = getBinding(findDropdown().element, 'gl-modal-directive');

        expect(binding.value).toBe(false);
      });
    });

    describe('when on project level', () => {
      it(`displays default action as ${CLUSTERS_ACTIONS.connectWithAgent}`, () => {
        expect(findDropdown().props('text')).toBe(CLUSTERS_ACTIONS.connectWithAgent);
      });

      it('renders correct modal id for the default action', () => {
        const binding = getBinding(findDropdown().element, 'gl-modal-directive');

        expect(binding.value).toBe(INSTALL_AGENT_MODAL_ID);
      });

      it('renders a dropdown with 3 actions items', () => {
        expect(findDropdownItemIds()).toEqual([
          'create-cluster-link',
          'new-cluster-link',
          'connect-cluster-link',
        ]);
      });

      it('renders correct texts for the dropdown items', () => {
        expect(findDropdownItemTexts()).toEqual([
          CLUSTERS_ACTIONS.createCluster,
          CLUSTERS_ACTIONS.createClusterCertificate,
          CLUSTERS_ACTIONS.connectClusterCertificate,
        ]);
      });

      it('renders correct href attributes for the links', () => {
        expect(findNewClusterDocsLink().attributes('href')).toBe(newClusterDocsPath);
        expect(findNewClusterLink().attributes('href')).toBe(newClusterPath);
        expect(findConnectClusterLink().attributes('href')).toBe(addClusterPath);
      });
    });

    describe('when on group or admin level', () => {
      beforeEach(() => {
        createWrapper({ displayClusterAgents: false });
      });

      it(`displays default action as ${CLUSTERS_ACTIONS.connectClusterDeprecated}`, () => {
        expect(findDropdown().props('text')).toBe(CLUSTERS_ACTIONS.connectClusterDeprecated);
      });

      it('renders a dropdown with 1 action item', () => {
        expect(findDropdownItemIds()).toEqual(['new-cluster-link']);
      });

      it('renders correct text for the dropdown item', () => {
        expect(findDropdownItemTexts()).toEqual([CLUSTERS_ACTIONS.createClusterDeprecated]);
      });

      it('renders correct href attributes for the links', () => {
        expect(findNewClusterLink().attributes('href')).toBe(newClusterPath);
      });

      it('does not bind dropdown button to modal', () => {
        const binding = getBinding(findDropdown().element, 'gl-modal-directive');

        expect(binding.value).toBe(false);
      });
    });
  });

  describe('when the certificate based clusters not enabled', () => {
    beforeEach(() => {
      createWrapper({ certificateBasedClustersEnabled: false });
    });

    it(`displays default action as ${CLUSTERS_ACTIONS.connectCluster}`, () => {
      expect(findDropdown().props('text')).toBe(CLUSTERS_ACTIONS.connectCluster);
    });

    it('renders correct modal id for the default action', () => {
      const binding = getBinding(findDropdown().element, 'gl-modal-directive');

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
