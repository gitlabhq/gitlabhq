<script>
import { mapState, mapActions } from 'vuex';
import { GlDrawer } from '@gitlab/ui';

export default {
  components: {
    GlDrawer,
  },
  props: {
    features: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    ...mapState(['open']),
    parsedFeatures() {
      let features;

      try {
        features = JSON.parse(this.$props.features) || [];
      } catch (err) {
        features = [];
      }

      return features;
    },
  },
  methods: {
    ...mapActions(['closeDrawer']),
  },
};
</script>

<template>
  <div>
    <gl-drawer class="mt-6" :open="open" @close="closeDrawer">
      <template #header>
        <h4>{{ __("What's new at GitLab") }}</h4>
      </template>
      <template>
        <ul>
          <li v-for="feature in parsedFeatures" :key="feature.title">
            <h5>{{ feature.title }}</h5>
            <p>{{ feature.body }}</p>
          </li>
        </ul>
      </template>
    </gl-drawer>
  </div>
</template>
