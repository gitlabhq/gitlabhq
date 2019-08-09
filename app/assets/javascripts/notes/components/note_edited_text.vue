<script>
/* eslint-disable @gitlab/vue-i18n/no-bare-strings */
import timeAgoTooltip from '../../vue_shared/components/time_ago_tooltip.vue';

export default {
  name: 'EditedNoteText',
  components: {
    timeAgoTooltip,
  },
  props: {
    actionText: {
      type: String,
      required: true,
    },
    actionDetailText: {
      type: String,
      required: false,
      default: '',
    },
    editedAt: {
      type: String,
      required: false,
      default: null,
    },
    editedBy: {
      type: Object,
      required: false,
      default: null,
    },
    className: {
      type: String,
      required: false,
      default: 'edited-text',
    },
  },
};
</script>

<template>
  <div :class="className">
    {{ actionText }}
    <template v-if="editedBy">
      by
      <a :href="editedBy.path" :data-user-id="editedBy.id" class="js-user-link author-link">
        {{ editedBy.name }}
      </a>
    </template>
    {{ actionDetailText }}
    <time-ago-tooltip :time="editedAt" tooltip-placement="bottom" />
  </div>
</template>
