<script>
import { GlCard, GlToggle, GlLink } from '@gitlab/ui';

export default {
  components: {
    GlCard,
    GlToggle,
    GlLink,
  },
  props: {
    providers: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <ul class="gl-list-style-none gl-m-0 gl-p-0">
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
