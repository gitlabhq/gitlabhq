import { GlCard, GlLoadingIcon, GlSprintf, GlBadge } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ClustersViewAll from '~/clusters_list/components/clusters_view_all.vue';
import Agents from '~/clusters_list/components/agents.vue';
import Clusters from '~/clusters_list/components/clusters.vue';
import {
  AGENT,
  CERTIFICATE_BASED,
  AGENT_CARD_INFO,
  CERTIFICATE_BASED_CARD_INFO,
  MAX_CLUSTERS_LIST,
} from '~/clusters_list/constants';
import { sprintf } from '~/locale';

Vue.use(Vuex);

const defaultBranchName = 'default-branch';

describe('ClustersViewAllComponent', () => {
  let wrapper;

  const event = {
    preventDefault: jest.fn(),
  };

  const propsData = {
    defaultBranchName,
  };

  const entryData = {
    loadingClusters: false,
    totalClusters: 0,
  };

  const findCards = () => wrapper.findAllComponents(GlCard);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAgentsComponent = () => wrapper.findComponent(Agents);
  const findClustersComponent = () => wrapper.findComponent(Clusters);
  const findCardsContainer = () => wrapper.findByTestId('clusters-cards-container');
  const findAgentCardTitle = () => wrapper.findByTestId('agent-card-title');
  const findRecommendedBadge = () => wrapper.findComponent(GlBadge);
  const findClustersCardTitle = () => wrapper.findByTestId('clusters-card-title');

  const createStore = (initialState) =>
    new Vuex.Store({
      state: initialState,
    });

  const createWrapper = ({ initialState = entryData } = {}) => {
    wrapper = shallowMountExtended(ClustersViewAll, {
      store: createStore(initialState),
      propsData,
      stubs: { GlCard, GlSprintf },
    });
  };

  beforeEach(() => {
    createWrapper();
  });

  describe('when agents and clusters are not loaded', () => {
    const initialState = {
      loadingClusters: true,
      totalClusters: 0,
    };
    beforeEach(() => {
      createWrapper({ initialState });
    });

    it('should show the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('when both agents and clusters are loaded', () => {
    beforeEach(() => {
      findAgentsComponent().vm.$emit('onAgentsLoad', 6);
    });

    it("shouldn't show the loading icon", () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('should make content visible', () => {
      expect(findCardsContainer().isVisible()).toBe(true);
    });

    it('should render 2 cards', () => {
      expect(findCards().length).toBe(2);
    });
  });

  describe('agents card', () => {
    it('should show recommended badge', () => {
      expect(findRecommendedBadge().exists()).toBe(true);
    });

    it('should render Agents component', () => {
      expect(findAgentsComponent().exists()).toBe(true);
    });

    it('should pass the limit prop', () => {
      expect(findAgentsComponent().props('limit')).toBe(MAX_CLUSTERS_LIST);
    });

    it('should pass the default-branch-name prop', () => {
      expect(findAgentsComponent().props('defaultBranchName')).toBe(defaultBranchName);
    });

    it('should emit `kasDisabled` event when received from Agents component', async () => {
      findAgentsComponent().vm.$emit('kasDisabled', true);
      await nextTick();

      expect(wrapper.emitted('kasDisabled')).toEqual([[true]]);
    });

    it('should emit `registerAgent` event when received from Agents component', async () => {
      findAgentsComponent().vm.$emit('registerAgent', 'new-agent-name');
      await nextTick();

      expect(wrapper.emitted('registerAgent')).toEqual([['new-agent-name']]);
    });

    describe('when there are no agents', () => {
      it('should show the empty title', () => {
        expect(findAgentCardTitle().text()).toBe(AGENT_CARD_INFO.emptyTitle);
      });
    });

    describe('when the agents are present', () => {
      const findFooterLink = () => wrapper.findByTestId('agents-tab-footer-link');
      const agentsNumber = 7;

      beforeEach(() => {
        findAgentsComponent().vm.$emit('onAgentsLoad', agentsNumber);
      });

      it('should show the correct title', () => {
        expect(findAgentCardTitle().text()).toBe(
          sprintf(AGENT_CARD_INFO.title, { number: MAX_CLUSTERS_LIST, total: agentsNumber }),
        );
      });

      it('should show the link to the Agents tab in the footer', () => {
        expect(findFooterLink().exists()).toBe(true);
        expect(findFooterLink().text()).toBe(
          sprintf(AGENT_CARD_INFO.footerText, { number: agentsNumber }),
        );
        expect(findFooterLink().attributes('href')).toBe(`?tab=${AGENT}`);
      });

      describe('when clicking on the footer link', () => {
        beforeEach(() => {
          findFooterLink().vm.$emit('click', event);
        });

        it('should trigger tab change', () => {
          expect(wrapper.emitted('changeTab')).toEqual([[AGENT]]);
        });
      });
    });
  });

  describe('clusters tab', () => {
    it('should pass the limit prop', () => {
      expect(findClustersComponent().props('limit')).toBe(MAX_CLUSTERS_LIST);
    });

    describe('when there are no clusters', () => {
      it('should show the empty title', () => {
        expect(findClustersCardTitle().text()).toBe(CERTIFICATE_BASED_CARD_INFO.emptyTitle);
      });
    });

    describe('when the clusters are present', () => {
      const findFooterLink = () => wrapper.findByTestId('clusters-tab-footer-link');

      const clustersNumber = 7;
      const initialState = {
        loadingClusters: false,
        totalClusters: clustersNumber,
      };

      beforeEach(() => {
        createWrapper({ initialState });
      });

      it('should show the correct title', () => {
        expect(findClustersCardTitle().text()).toBe(
          sprintf(CERTIFICATE_BASED_CARD_INFO.title, {
            number: MAX_CLUSTERS_LIST,
            total: clustersNumber,
          }),
        );
      });

      it('should show the link to the Clusters tab in the footer', () => {
        expect(findFooterLink().exists()).toBe(true);
        expect(findFooterLink().text()).toBe(
          sprintf(CERTIFICATE_BASED_CARD_INFO.footerText, { number: clustersNumber }),
        );
      });

      describe('when clicking on the footer link', () => {
        beforeEach(() => {
          findFooterLink().vm.$emit('click', event);
        });

        it('should trigger tab change', () => {
          expect(wrapper.emitted('changeTab')).toEqual([[CERTIFICATE_BASED]]);
        });
      });
    });
  });
});
