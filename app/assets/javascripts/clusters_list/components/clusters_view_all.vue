<script>
import { GlCard, GlSprintf, GlPopover, GlLink, GlBadge, GlLoadingIcon } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import { AGENT_CARD_INFO, CERTIFICATE_BASED_CARD_INFO, MAX_CLUSTERS_LIST } from '../constants';
import Clusters from './clusters.vue';
import Agents from './agents.vue';

export default {
  components: {
    GlCard,
    GlSprintf,
    GlPopover,
    GlLink,
    GlBadge,
    GlLoadingIcon,
    Clusters,
    Agents,
  },
  MAX_CLUSTERS_LIST,
  i18n: {
    agent: AGENT_CARD_INFO,
    certificate: CERTIFICATE_BASED_CARD_INFO,
  },
  props: {
    defaultBranchName: {
      default: '.noBranch',
      required: false,
      type: String,
    },
  },
  data() {
    return {
      loadingAgents: true,
      totalAgents: null,
    };
  },
  computed: {
    ...mapState(['loadingClusters', 'totalClusters']),
    isLoading() {
      return this.loadingAgents || this.loadingClusters;
    },
    agentsCardTitle() {
      let cardTitle;
      if (this.totalAgents > 0) {
        cardTitle = {
          message: AGENT_CARD_INFO.title,
          number: this.totalAgents < MAX_CLUSTERS_LIST ? this.totalAgents : MAX_CLUSTERS_LIST,
          total: this.totalAgents,
        };
      } else {
        cardTitle = {
          message: AGENT_CARD_INFO.emptyTitle,
        };
      }

      return cardTitle;
    },
    clustersCardTitle() {
      let cardTitle;
      if (this.totalClusters > 0) {
        cardTitle = {
          message: CERTIFICATE_BASED_CARD_INFO.title,
          number: this.totalClusters < MAX_CLUSTERS_LIST ? this.totalClusters : MAX_CLUSTERS_LIST,
          total: this.totalClusters,
        };
      } else {
        cardTitle = {
          message: CERTIFICATE_BASED_CARD_INFO.emptyTitle,
        };
      }

      return cardTitle;
    },
  },
  methods: {
    cardFooterNumber(number) {
      return number > MAX_CLUSTERS_LIST ? number : '';
    },
    onAgentsLoad(number) {
      this.totalAgents = number;
      this.loadingAgents = false;
    },
    onKasDisabled($event) {
      this.$emit('kasDisabled', $event);
    },
    onRegisterAgent($event) {
      this.$emit('registerAgent', $event);
    },
    changeTab($event, tab) {
      $event.preventDefault();
      this.$emit('changeTab', tab);
    },
  },
};
</script>
<template>
  <div>
    <gl-loading-icon v-if="isLoading" size="lg" />
    <div v-show="!isLoading" data-testid="clusters-cards-container">
      <gl-card
        header-class="gl-flex gl-items-center gl-justify-between"
        body-class="gl-pb-0 cluster-card-item"
        footer-class="gl-text-right"
      >
        <template #header>
          <h3 data-testid="agent-card-title" class="gl-my-0 gl-text-size-h2 gl-font-normal">
            <gl-sprintf :message="agentsCardTitle.message"
              ><template #number>{{ agentsCardTitle.number }}</template>
              <template #total>{{ agentsCardTitle.total }}</template>
            </gl-sprintf>
          </h3>

          <gl-badge id="clusters-recommended-badge" variant="info">{{
            $options.i18n.agent.tooltip.label
          }}</gl-badge>

          <gl-popover
            target="clusters-recommended-badge"
            container="viewport"
            placement="bottom"
            :title="$options.i18n.agent.tooltip.title"
          >
            <p class="gl-mb-0">
              <gl-sprintf :message="$options.i18n.agent.tooltip.text">
                <template #link="{ content }">
                  <gl-link
                    :href="$options.i18n.agent.tooltip.link"
                    target="_blank"
                    class="gl-text-sm"
                  >
                    {{ content }}</gl-link
                  >
                </template>
              </gl-sprintf>
            </p>
          </gl-popover>
        </template>

        <agents
          :limit="$options.MAX_CLUSTERS_LIST"
          :default-branch-name="defaultBranchName"
          :is-child-component="true"
          @onAgentsLoad="onAgentsLoad"
          @kasDisabled="onKasDisabled"
          @registerAgent="onRegisterAgent"
        />

        <template #footer>
          <gl-link
            v-if="totalAgents"
            data-testid="agents-tab-footer-link"
            :href="`?tab=${$options.i18n.agent.tabName}`"
            @click="changeTab($event, $options.i18n.agent.tabName)"
            ><gl-sprintf :message="$options.i18n.agent.footerText"
              ><template #number>{{ cardFooterNumber(totalAgents) }}</template></gl-sprintf
            ></gl-link
          >
        </template>
      </gl-card>

      <gl-card
        class="gl-mt-6"
        header-class="gl-flex gl-items-center gl-justify-between"
        body-class="gl-pb-0 cluster-card-item"
        footer-class="gl-text-right"
      >
        <template #header>
          <h3 class="gl-my-1 gl-text-size-h2 gl-font-normal" data-testid="clusters-card-title">
            <gl-sprintf :message="clustersCardTitle.message"
              ><template #number>{{ clustersCardTitle.number }}</template>
              <template #total>{{ clustersCardTitle.total }}</template>
            </gl-sprintf>
          </h3>
          <gl-badge variant="warning">{{ $options.i18n.certificate.badgeText }}</gl-badge>
        </template>

        <clusters :limit="$options.MAX_CLUSTERS_LIST" />

        <template #footer>
          <gl-link
            v-if="totalClusters"
            data-testid="clusters-tab-footer-link"
            :href="`?tab=${$options.i18n.certificate.tabName}`"
            @click="changeTab($event, $options.i18n.certificate.tabName)"
            ><gl-sprintf :message="$options.i18n.certificate.footerText"
              ><template #number>{{ cardFooterNumber(totalClusters) }}</template></gl-sprintf
            ></gl-link
          >
        </template>
      </gl-card>
    </div>
  </div>
</template>
