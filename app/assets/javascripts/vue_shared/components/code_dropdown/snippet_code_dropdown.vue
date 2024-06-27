<script>
import { GlDisclosureDropdown, GlTooltipDirective } from '@gitlab/ui';
import { getHTTPProtocol } from '~/lib/utils/url_utility';
import { __, sprintf } from '~/locale';
import CodeDropdownItem from './code_dropdown_item.vue';

export default {
  components: {
    GlDisclosureDropdown,
    CodeDropdownItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    sshLink: {
      type: String,
      required: false,
      default: '',
    },
    httpLink: {
      type: String,
      required: false,
      default: '',
    },
    url: {
      type: String,
      required: true,
    },
    embeddable: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    httpLabel() {
      const protocol = this.httpLink ? getHTTPProtocol(this.httpLink)?.toUpperCase() : '';
      return sprintf(__('Clone with %{protocol}'), { protocol });
    },
    sections() {
      const sections = [
        { label: __('Clone with SSH'), link: this.sshLink, testId: 'copy-ssh-url' },
        { label: this.httpLabel, link: this.httpLink, testId: 'copy-http-url' },
      ];

      if (this.embeddable) {
        sections.push(
          {
            label: __('Embed'),
            // eslint-disable-next-line no-useless-escape
            link: `<script src="${encodeURI(this.url)}.js"><\/script>`,
            testId: 'copy-embedded-code',
          },
          { label: __('Share'), link: this.url, testId: 'copy-share-url' },
        );
      }
      return sections;
    },
  },
  labels: {
    defaultLabel: __('Code'),
  },
};
</script>
<template>
  <gl-disclosure-dropdown
    category="primary"
    variant="confirm"
    placement="bottom-end"
    block
    :toggle-text="$options.labels.defaultLabel"
  >
    <code-dropdown-item
      v-for="{ label, link, testId } in sections"
      :key="label"
      :label="label"
      :link="link"
      :test-id="`${testId}-button`"
      :data-testid="testId"
      label-class="gl-font-sm! gl-pt-2!"
    />
  </gl-disclosure-dropdown>
</template>
