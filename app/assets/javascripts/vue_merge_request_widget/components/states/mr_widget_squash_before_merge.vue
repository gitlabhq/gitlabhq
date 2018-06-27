<script>
import Icon from '~/vue_shared/components/icon.vue';
import eventHub from '~/vue_merge_request_widget/event_hub';
import tooltip from '~/vue_shared/directives/tooltip';

export default {
  components: {
    Icon,
  },
  directives: {
    tooltip,
  },
  props: {
    mr: {
      type: Object,
      required: true,
    },
    isMergeButtonDisabled: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      squashBeforeMerge: this.mr.squash,
    };
  },
  methods: {
    updateSquashModel() {
      eventHub.$emit('MRWidgetUpdateSquash', this.squashBeforeMerge);
    },
  },
};
</script>

<template>
  <div class="accept-control inline">
    <label class="merge-param-checkbox">
      <input
        :disabled="isMergeButtonDisabled"
        v-model="squashBeforeMerge"
        type="checkbox"
        name="squash"
        class="qa-squash-checkbox"
        @change="updateSquashModel"
      />
      {{ __('Squash commits') }}
    </label>
    <a
      v-tooltip
      :href="mr.squashBeforeMergeHelpPath"
      data-title="About this feature"
      data-placement="bottom"
      target="_blank"
      rel="noopener noreferrer nofollow"
      data-container="body"
    >
      <icon
        name="question-o"
      />
    </a>
  </div>
</template>
