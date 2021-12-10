<script>
import { GlCard, GlToggle, GlLink, GlSkeletonLoader } from '@gitlab/ui';

export default {
  components: {
    GlCard,
    GlToggle,
    GlLink,
    GlSkeletonLoader,
  },
  props: {
    providers: {
      type: Array,
      required: true,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <div
    v-if="loading"
    class="gl-bg-white gl-py-6 gl-rounded-base gl-border-1 gl-border-solid gl-border-gray-100"
  >
    <gl-skeleton-loader :width="350" :height="44">
      <rect width="200" height="8" x="10" y="0" rx="4" />
      <rect width="300" height="8" x="10" y="15" rx="4" />
      <rect width="100" height="8" x="10" y="35" rx="4" />
    </gl-skeleton-loader>
  </div>
  <ul v-else class="gl-list-style-none gl-m-0 gl-p-0">
    <li v-for="{ id, isEnabled, name, description, url } in providers" :key="id" class="gl-mb-6">
      <gl-card>
        <div class="gl-display-flex">
          <gl-toggle :value="isEnabled" :label="__('Training mode')" label-position="hidden" />
          <div class="gl-ml-5">
            <h3 class="gl-font-lg gl-m-0 gl-mb-2">{{ name }}</h3>
            <p>
              {{ description }}
              <gl-link :href="url" target="_blank">{{ __('Learn more.') }}</gl-link>
            </p>
          </div>
        </div>
      </gl-card>
    </li>
  </ul>
</template>
