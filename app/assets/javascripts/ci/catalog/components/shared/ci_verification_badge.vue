<script>
import { GlIcon, GlLink, GlPopover, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { VerificationLevel } from '../../constants';

export default {
  i18n: {
    verificationLevelPopoverLink: s__('CiCatalog|Learn more about designated creators'),
  },
  VerificationLevel,
  verificationHelpPagePath: helpPagePath('ci/components/index', { anchor: 'verified-components' }),
  components: {
    GlIcon,
    GlLink,
    GlPopover,
    GlSprintf,
  },
  props: {
    resourceId: {
      type: String,
      required: true,
    },
    showText: {
      type: Boolean,
      default: false,
      required: false,
    },
    verificationLevel: {
      type: String,
      required: true,
    },
  },
  computed: {
    popoverTarget() {
      return `${this.resourceId}-verification-icon`;
    },
  },
};
</script>

<template>
  <span>
    <span :id="popoverTarget">
      <gl-icon
        class="gl-text-blue-500 gl-ml-1"
        :name="$options.VerificationLevel[verificationLevel].icon"
      />
      <span
        v-if="showText"
        data-testid="verification-badge-text"
        class="gl-text-blue-500 gl-font-weight-bold gl-cursor-default"
      >
        {{ $options.VerificationLevel[verificationLevel].badgeText }}
      </span>
    </span>
    <gl-popover :target="popoverTarget" triggers="hover focus">
      <div class="gl-display-flex gl-flex-direction-column gl-gap-4">
        <span>
          <gl-sprintf :message="$options.VerificationLevel[verificationLevel].popoverText">
            <template #bold="{ content }">
              <strong>
                {{ content }}
              </strong>
            </template>
          </gl-sprintf>
        </span>
        <gl-link :href="$options.verificationHelpPagePath" target="_blank">
          {{ $options.i18n.verificationLevelPopoverLink }}
        </gl-link>
      </div>
    </gl-popover>
  </span>
</template>
