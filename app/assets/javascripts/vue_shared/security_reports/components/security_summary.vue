<script>
import { GlSprintf } from '@gitlab/ui';
import { SEVERITY_CLASS_NAME_MAP } from './constants';

export default {
  components: {
    GlSprintf,
  },
  props: {
    message: {
      type: Object,
      required: true,
    },
  },
  computed: {
    shouldShowCountMessage() {
      return !this.message.status && Boolean(this.message.countMessage);
    },
  },
  methods: {
    getSeverityClass(severity) {
      return SEVERITY_CLASS_NAME_MAP[severity];
    },
  },
  slotNames: ['critical', 'high', 'other'],
  spacingClasses: {
    critical: 'gl-pl-4',
    high: 'gl-px-2',
    other: 'gl-px-2',
  },
};
</script>

<template>
  <span>
    <gl-sprintf :message="message.message">
      <template #total="{ content }">
        <strong>{{ content }}</strong>
      </template>
    </gl-sprintf>
    <span v-if="shouldShowCountMessage" class="gl-font-sm">
      <gl-sprintf :message="message.countMessage">
        <template v-for="slotName in $options.slotNames" #[slotName]="{ content }">
          <span :key="slotName">
            <strong
              v-if="message[slotName] > 0"
              :class="[getSeverityClass(slotName), $options.spacingClasses[slotName]]"
            >
              {{ content }}
            </strong>
            <span v-else :class="$options.spacingClasses[slotName]">
              {{ content }}
            </span>
          </span>
        </template>
      </gl-sprintf>
    </span>
  </span>
</template>
