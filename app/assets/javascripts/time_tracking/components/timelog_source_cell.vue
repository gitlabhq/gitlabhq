<script>
import { GlLink } from '@gitlab/ui';
import { issuableStatusText } from '~/issues/constants';

export default {
  components: {
    GlLink,
  },
  props: {
    timelog: {
      type: Object,
      required: true,
    },
  },
  computed: {
    subject() {
      const { issue, mergeRequest } = this.timelog;
      return issue || mergeRequest;
    },
    issuableStatus() {
      return issuableStatusText[this.subject.state];
    },
    issuableFullReference() {
      return this.timelog.project.fullPath + this.subject.reference;
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-flex-col gl-gap-2 !gl-text-left">
    <gl-link
      :href="subject.webUrl"
      class="gl-font-bold gl-text-default hover:gl-text-default"
      data-testid="title-container"
    >
      {{ subject.title }}
    </gl-link>
    <span>
      <gl-link
        :href="subject.webUrl"
        class="gl-text-default hover:gl-text-default"
        data-testid="reference-container"
      >
        {{ issuableFullReference }}
      </gl-link>
      • <span data-testid="state-container">{{ issuableStatus }}</span>
    </span>
  </div>
</template>
