<script>
import { GlButton, GlDisclosureDropdown } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { PROMO_URL } from 'jh_else_ce/lib/utils/url_utility';

export default {
  components: {
    GlButton,
    GlDisclosureDropdown,
  },
  inject: ['isSaas'],
  props: {
    pricingUrl: {
      type: String,
      required: true,
    },
  },
  computed: {
    exploreItem() {
      return {
        text: __('Explore'),
        href: '/explore',
      };
    },
    items() {
      return [
        {
          text: s__('LoggedOutMarketingHeader|Why GitLab'),
          href: this.promoUrl('/why-gitlab'),
        },
        {
          text: s__('LoggedOutMarketingHeader|Pricing'),
          href: this.pricingUrl,
        },
        {
          text: s__('LoggedOutMarketingHeader|Contact Sales'),
          href: this.promoUrl('/sales'),
          extraAttrs: {
            dataMenuOnly: true,
          },
        },
        { ...this.exploreItem },
      ];
    },
    visibleItems() {
      return this.items.filter((item) => !item.extraAttrs?.dataMenuOnly);
    },
  },
  methods: {
    promoUrl(url) {
      return `${PROMO_URL}${url}`;
    },
  },
};
</script>

<template>
  <div class="gl-flex">
    <gl-button
      v-if="!isSaas"
      :href="exploreItem.href"
      category="tertiary"
      data-testid="explore-button"
    >
      {{ exploreItem.text }}
    </gl-button>
    <template v-else>
      <gl-disclosure-dropdown
        icon="ellipsis_v"
        category="tertiary"
        :toggle-text="__('Menu')"
        text-sr-only
        no-caret
        :items="items"
        class="gl-block lg:gl-hidden"
      />
      <ul class="gl-m-0 gl-hidden gl-list-none gl-gap-2 gl-p-0 lg:gl-flex" data-testid="menu">
        <li v-for="(item, index) in visibleItems" :key="index">
          <gl-button :href="item.href" category="tertiary">
            {{ item.text }}
          </gl-button>
        </li>
      </ul>
    </template>
  </div>
</template>
