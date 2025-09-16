<script>
import { GlCard, GlButton } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import { InternalEvents } from '~/tracking';

const CARD_VARIANTS = {
  PURPLE: 'purple',
  RED: 'red',
};

const I18N = {
  ariaLabel: s__('FeaturedCard|Learn more about %{title}, opens in a new tab'),
};

export default {
  name: 'FeaturedCard',
  components: {
    GlCard,
    GlButton,
  },
  mixins: [InternalEvents.mixin()],
  i18n: I18N,
  props: {
    title: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: true,
    },
    buttonLink: {
      type: String,
      required: true,
    },
    trackingEvent: {
      type: String,
      required: true,
    },
    variant: {
      type: String,
      required: false,
      default: CARD_VARIANTS.PURPLE,
      validator: (value) => Object.values(CARD_VARIANTS).includes(value),
    },
  },
  computed: {
    ariaLabel() {
      return sprintf(this.$options.i18n.ariaLabel, { title: this.title });
    },
    wrapperClasses() {
      return ['featured-card-wrapper', `featured-card-wrapper--${this.variant}`];
    },
    cardClasses() {
      return ['featured-card', `featured-card--${this.variant}`];
    },
  },
  methods: {
    handleCardClick() {
      this.trackEvent(this.trackingEvent);
    },
  },
};
</script>

<template>
  <gl-button
    variant="link"
    category="tertiary"
    class="featured-card-button gl-display-block gl-w-full gl-border-0 gl-p-0 gl-text-left"
    :href="buttonLink"
    target="_blank"
    rel="noopener noreferrer"
    :aria-label="ariaLabel"
    role="link"
    :data-testid="`featured-card-${variant}`"
    block
    @click="handleCardClick"
  >
    <div :class="wrapperClasses" role="presentation">
      <gl-card
        :class="cardClasses"
        class="gl-mb-0 gl-border-0"
        body-class="featured-card-body"
        role="presentation"
      >
        <h3 class="featured-card-title gl-font-weight-bold gl-mb-1 gl-mt-0">
          {{ title }}
        </h3>
        <p class="featured-card-description gl-mb-0">
          {{ description }}
        </p>
      </gl-card>
    </div>
  </gl-button>
</template>
