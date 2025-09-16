<script>
import { GlIcon, GlButton } from '@gitlab/ui';
import { DOCS_URL } from 'jh_else_ce/lib/utils/url_utility';
import { s__ } from '~/locale';
import FeaturedCard from './featured_card.vue';

export default {
  name: 'FeaturedCarousel',
  components: {
    GlIcon,
    GlButton,
    FeaturedCard,
  },
  data() {
    return {
      currentCard: 0,
    };
  },
  computed: {
    isPreviousDisabled() {
      return this.currentCard === 0;
    },
    isNextDisabled() {
      return this.currentCard >= 1;
    },
    cardCounterValue() {
      return this.sprintf(this.$options.i18n.cardCounter, {
        current: this.currentCard + 1,
        total: 2,
      });
    },
    featureCards() {
      const granularCard = {
        title: this.$options.i18n.granularCardTitle,
        description: this.$options.i18n.granularCardDescription,
        buttonLink: this.$options.GRANULAR_CARD_URL,
        trackingEvent: 'click_learn_more_in_granular_access_featured_update_card',
        variant: 'purple',
      };

      const duoProCard = {
        title: this.$options.i18n.duoProCardTitle,
        description: this.$options.i18n.duoProCardDescription,
        buttonLink: this.$options.GITLAB_DUO_PRO_CARD_URL,
        trackingEvent: 'click_learn_more_in_duo_core_featured_update_card',
        variant: 'red',
      };

      const releaseDate = new Date('2025-09-18T00:00:00Z');
      const currentDate = new Date();

      return currentDate >= releaseDate ? [duoProCard, granularCard] : [granularCard, duoProCard];
    },
    firstCard() {
      return this.featureCards[0];
    },
    secondCard() {
      return this.featureCards[1];
    },
  },
  methods: {
    nextCard() {
      this.currentCard += 1;
    },
    previousCard() {
      this.currentCard -= 1;
    },
  },
  i18n: {
    featuredUpdates: s__('FeaturedUpdate|Featured updates'),
    cardCounter: s__('FeaturedUpdate|%{current} / %{total}'),
    granularCardTitle: s__('FeaturedUpdate|Granular access controls for GitLab Duo Core'),
    granularCardDescription: s__(
      'FeaturedUpdate|Set detailed permissions for GitLab Duo Core across projects and groups to fit your workflow.',
    ),
    duoProCardTitle: s__('FeaturedUpdate|Explore GitLab Duo Core'),
    duoProCardDescription: s__(
      'FeaturedUpdate|Discover AI-native features including Code Suggestions and Chat in your IDE in GitLab Premium and Ultimate.',
    ),
  },
  GRANULAR_CARD_URL: `${DOCS_URL}/user/gitlab_duo/turn_on_off`,
  GITLAB_DUO_PRO_CARD_URL: `${DOCS_URL}/subscriptions/subscription-add-ons/#gitlab-duo-core`,
};
</script>

<template>
  <div class="gl-p-3 gl-pb-5">
    <div class="gl-mb-5 gl-flex gl-h-6 gl-items-center gl-justify-between">
      <div class="gl-flex gl-items-center gl-gap-3">
        <gl-icon name="compass" :size="16" />
        <h5 class="gl-m-0">{{ $options.i18n.featuredUpdates }}</h5>
      </div>
      <div class="gl-flex gl-items-center gl-gap-2">
        <gl-button
          category="tertiary"
          :disabled="isPreviousDisabled"
          :style="{ border: 'none' }"
          data-testid="card-carousel-previous-button"
          :aria-label="__('Previous card')"
          @click="previousCard"
        >
          <gl-icon name="chevron-lg-left" />
        </gl-button>
        <span data-testid="card-counter"> {{ cardCounterValue }} </span>
        <gl-button
          class="gl-border-none!"
          category="tertiary"
          :disabled="isNextDisabled"
          :style="{ border: 'none' }"
          data-testid="card-carousel-next-button"
          :aria-label="__('Next card')"
          @click="nextCard"
        >
          <gl-icon name="chevron-lg-right" />
        </gl-button>
      </div>
    </div>

    <div class="gl-overflow-hidden">
      <div
        class="gl-flex gl-transition-transform"
        :style="{ transform: `translateX(-${currentCard * 100}%)` }"
      >
        <div class="gl-w-full gl-flex-shrink-0">
          <featured-card
            :title="firstCard.title"
            :description="firstCard.description"
            :button-link="firstCard.buttonLink"
            data-testid="whats-new-featured-card-first"
            :tracking-event="firstCard.trackingEvent"
            :variant="firstCard.variant"
          />
        </div>
        <div class="gl-w-full gl-flex-shrink-0">
          <featured-card
            :title="secondCard.title"
            :description="secondCard.description"
            :button-link="secondCard.buttonLink"
            data-testid="whats-new-featured-card-second"
            :tracking-event="secondCard.trackingEvent"
            :variant="secondCard.variant"
          />
        </div>
      </div>
    </div>
  </div>
</template>
