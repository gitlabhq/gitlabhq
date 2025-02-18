<script>
import { GlIcon, GlLink, GlPopover, GlSprintf } from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import {
  VERIFICATION_LEVELS,
  VERIFICATION_LEVEL_VERIFIED_CREATOR_MAINTAINED,
} from '../../constants';

export default {
  i18n: {
    verifiedCreatorPopoverLink: s__('CiCatalog|What are verified component creators?'),
    verificationLevelPopoverLink: s__('CiCatalog|Learn more about designated creators'),
  },
  verificationHelpPagePath: helpPagePath('ci/components/_index', {
    anchor: 'verified-component-creators',
  }),
  verificationLevelOptions: VERIFICATION_LEVELS,
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
    isMobile() {
      return ['sm', 'xs'].includes(GlBreakpointInstance.getBreakpointSize());
    },
    popoverLink() {
      return this.verificationLevel === VERIFICATION_LEVEL_VERIFIED_CREATOR_MAINTAINED
        ? this.$options.i18n.verifiedCreatorPopoverLink
        : this.$options.i18n.verificationLevelPopoverLink;
    },
    popoverPlacement() {
      return this.isMobile ? 'bottom' : 'right';
    },
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
        class="gl-ml-1 gl-text-blue-500"
        :name="$options.verificationLevelOptions[verificationLevel].icon"
      />
      <span
        v-if="showText"
        data-testid="verification-badge-text"
        class="gl-cursor-default gl-font-bold gl-text-blue-500"
      >
        {{ $options.verificationLevelOptions[verificationLevel].badgeText }}
      </span>
    </span>
    <gl-popover :target="popoverTarget" triggers="hover focus" :placement="popoverPlacement">
      <div class="gl-flex gl-flex-col gl-gap-4">
        <span>
          <gl-sprintf :message="$options.verificationLevelOptions[verificationLevel].popoverText">
            <template #bold="{ content }">
              <strong>
                {{ content }}
              </strong>
            </template>
          </gl-sprintf>
        </span>
        <gl-link :href="$options.verificationHelpPagePath" target="_blank">
          {{ popoverLink }}
        </gl-link>
      </div>
    </gl-popover>
  </span>
</template>
