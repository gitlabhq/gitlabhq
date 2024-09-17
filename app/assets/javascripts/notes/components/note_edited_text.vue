<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { EDITED_TEXT } from '../i18n';

export default {
  name: 'EditedNoteText',
  components: {
    GlSprintf,
    GlLink,
    TimeAgoTooltip,
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
  i18n: EDITED_TEXT,
};
</script>

<template>
  <div :class="className" class="gl-text-sm">
    <gl-sprintf v-if="editedBy" :message="$options.i18n.actionWithAuthor">
      <template #actionText>
        {{ actionText }}
      </template>
      <template #actionDetail>
        {{ actionDetailText }}
      </template>
      <template #timeago>
        <time-ago-tooltip :time="editedAt" tooltip-placement="bottom" />
      </template>
      <template #author>
        <gl-link
          :href="editedBy.path"
          :data-user-id="editedBy.id"
          class="js-user-link author-link hover:gl-underline"
        >
          {{ editedBy.name }}
        </gl-link>
      </template>
    </gl-sprintf>
    <gl-sprintf v-else :message="$options.i18n.actionWithoutAuthor">
      <template #actionText>
        {{ actionText }}
      </template>
      <template #actionDetail>
        {{ actionDetailText }}
      </template>
      <template #timeago>
        <time-ago-tooltip :time="editedAt" tooltip-placement="bottom" />
      </template>
    </gl-sprintf>
  </div>
</template>
