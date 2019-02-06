<script>
import { mapActions } from 'vuex';
import { GlTooltipDirective, GlButton } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  name: 'ReplyButton',
  components: {
    Icon,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    noteId: {
      type: String,
      required: true,
    },
  },
  methods: {
    ...mapActions(['convertToDiscussion']),
  },
};
</script>

<template>
  <div class="note-actions-item">
    <gl-button
      ref="button"
      v-gl-tooltip.bottom
      class="note-action-button"
      variant="transparent"
      :title="__('Reply to comment')"
      @click="convertToDiscussion(noteId)"
    >
      <icon name="comment" css-classes="link-highlight" />
    </gl-button>
  </div>
</template>
