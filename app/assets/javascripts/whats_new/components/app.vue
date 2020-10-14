<script>
import { mapState, mapActions } from 'vuex';
import { GlDrawer, GlBadge, GlIcon, GlLink } from '@gitlab/ui';
import SkeletonLoader from './skeleton_loader.vue';
import Tracking from '~/tracking';

const trackingMixin = Tracking.mixin();

export default {
  components: {
    GlDrawer,
    GlBadge,
    GlIcon,
    GlLink,
    SkeletonLoader,
  },
  mixins: [trackingMixin],
  props: {
    storageKey: {
      type: String,
      required: true,
      default: null,
    },
  },
  computed: {
    ...mapState(['open', 'features']),
  },
  mounted() {
    this.openDrawer(this.storageKey);
    this.fetchItems();

    const body = document.querySelector('body');
    const namespaceId = body.getAttribute('data-namespace-id');

    this.track('click_whats_new_drawer', { label: 'namespace_id', value: namespaceId });
  },
  methods: {
    ...mapActions(['openDrawer', 'closeDrawer', 'fetchItems']),
  },
};
</script>

<template>
  <div>
    <gl-drawer class="whats-new-drawer" :open="open" @close="closeDrawer">
      <template #header>
        <h4 class="page-title my-2">{{ __("What's new at GitLab") }}</h4>
      </template>
      <div class="pb-6">
        <template v-if="features">
          <div v-for="feature in features" :key="feature.title" class="mb-6">
            <gl-link
              :href="feature.url"
              target="_blank"
              data-testid="whats-new-title-link"
              data-track-event="click_whats_new_item"
              :data-track-label="feature.title"
              :data-track-property="feature.url"
            >
              <h5 class="gl-font-base">{{ feature.title }}</h5>
            </gl-link>
            <div v-if="feature.packages" class="gl-mb-3">
              <template v-for="package_name in feature.packages">
                <gl-badge :key="package_name" size="sm" class="whats-new-item-badge gl-mr-2">
                  <gl-icon name="license" />{{ package_name }}
                </gl-badge>
              </template>
            </div>
            <gl-link
              :href="feature.url"
              target="_blank"
              data-track-event="click_whats_new_item"
              :data-track-label="feature.title"
              :data-track-property="feature.url"
            >
              <img
                :alt="feature.title"
                :src="feature.image_url"
                class="img-thumbnail px-6 gl-py-3 whats-new-item-image"
              />
            </gl-link>
            <p class="gl-pt-3">{{ feature.body }}</p>
            <gl-link
              :href="feature.url"
              target="_blank"
              data-track-event="click_whats_new_item"
              :data-track-label="feature.title"
              :data-track-property="feature.url"
              >{{ __('Learn more') }}</gl-link
            >
          </div>
        </template>
        <div v-else class="gl-mt-5">
          <skeleton-loader />
          <skeleton-loader />
        </div>
      </div>
    </gl-drawer>
    <div v-if="open" class="whats-new-modal-backdrop modal-backdrop"></div>
  </div>
</template>
