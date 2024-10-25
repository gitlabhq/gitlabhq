<script>
import { GlSprintf, GlButton } from '@gitlab/ui';
import { toNounSeriesText } from '~/lib/utils/grammar';
import { s__, sprintf } from '~/locale';

export default {
  components: {
    GlSprintf,
    GlButton,
  },
  props: {
    emails: {
      type: Array,
      required: true,
    },
    numberOfLessParticipants: {
      type: Number,
      required: false,
      default: 3,
    },
  },
  data() {
    return {
      isShowingMoreParticipants: false,
    };
  },
  computed: {
    title() {
      return this.moreParticipantsAvailable
        ? toNounSeriesText(this.lessParticipants, { onlyCommas: true })
        : toNounSeriesText(this.emails);
    },
    lessParticipants() {
      return this.emails.slice(0, this.numberOfLessParticipants);
    },
    moreLabel() {
      return sprintf(s__('EmailParticipantsWarning|and %{moreCount} more'), {
        moreCount: this.emails.length - this.numberOfLessParticipants,
      });
    },
    moreParticipantsAvailable() {
      return !this.isShowingMoreParticipants && this.emails.length > this.numberOfLessParticipants;
    },
    message() {
      return this.moreParticipantsAvailable
        ? s__('EmailParticipantsWarning|%{emails}, %{andMore} will be notified of your comment.')
        : s__('EmailParticipantsWarning|%{emails} will be notified of your comment.');
    },
  },
  methods: {
    showMoreParticipants() {
      this.isShowingMoreParticipants = true;
    },
  },
};
</script>

<template>
  <div>
    <gl-sprintf :message="message">
      <template #andMore>
        <gl-button variant="link" class="gl-align-baseline" @click="showMoreParticipants">
          {{ moreLabel }}
        </gl-button>
      </template>
      <template #emails>
        <span>{{ title }}</span>
      </template>
    </gl-sprintf>
  </div>
</template>
