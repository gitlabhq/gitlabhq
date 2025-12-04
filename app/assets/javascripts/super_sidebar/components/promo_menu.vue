<script>
import {
  GlButton,
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
} from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { PROMO_URL } from 'jh_else_ce/lib/utils/url_utility';

export default {
  components: {
    GlButton,
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    GlDisclosureDropdownItem,
  },
  inject: ['isSaas'],
  props: {
    sidebarData: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    pricingUrl: {
      type: String,
      required: true,
    },
    allowSignUp: {
      type: Boolean,
      required: false,
      default: false,
    },
    signInVisible: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    showAuthButtons() {
      return this.allowSignUp || this.signInVisible;
    },
    exploreItem() {
      return {
        text: __('Explore'),
        href: '/explore',
      };
    },
    items() {
      if (!this.isSaas) {
        return [{ ...this.exploreItem }];
      }
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
    <gl-disclosure-dropdown
      icon="profile"
      category="tertiary"
      :toggle-text="__('Menu')"
      text-sr-only
      no-caret
      :items="items"
      class="gl-block lg:gl-hidden"
    >
      <gl-disclosure-dropdown-group v-if="showAuthButtons">
        <div class="gl-flex gl-flex-col gl-gap-3 gl-px-4 gl-py-3">
          <gl-button
            v-if="allowSignUp"
            :href="sidebarData.new_user_registration_path"
            variant="confirm"
            class="topbar-signup-button gl-basis-1/2"
            data-testid="topbar-signup-button"
          >
            {{ isSaas ? __('Get free trial') : __('Register') }}
          </gl-button>
          <gl-button
            v-if="signInVisible"
            :href="sidebarData.sign_in_path"
            class="gl-basis-1/2"
            data-testid="topbar-signin-button"
          >
            {{ __('Sign in') }}
          </gl-button>
        </div>
      </gl-disclosure-dropdown-group>
      <gl-disclosure-dropdown-group bordered>
        <gl-disclosure-dropdown-item v-for="item in items" :key="item.href" :item="item" />
      </gl-disclosure-dropdown-group>
    </gl-disclosure-dropdown>
    <ul class="gl-m-0 gl-hidden gl-list-none gl-gap-2 gl-p-0 lg:gl-flex" data-testid="menu">
      <li v-for="(item, index) in visibleItems" :key="index">
        <gl-button :href="item.href" category="tertiary">
          {{ item.text }}
        </gl-button>
      </li>
    </ul>
  </div>
</template>
