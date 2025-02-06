<script>
import { GlDisclosureDropdown, GlTooltipDirective } from '@gitlab/ui';
import { getHTTPProtocol } from '~/lib/utils/url_utility';
import { __, sprintf } from '~/locale';
import CodeDropdownCloneItem from '~/repository/components/code_dropdown/code_dropdown_clone_item.vue';

export default {
  components: {
    GlDisclosureDropdown,
    CodeDropdownCloneItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    sshUrl: {
      type: String,
      required: false,
      default: '',
    },
    httpUrl: {
      type: String,
      required: false,
      default: '',
    },
    kerberosUrl: {
      type: String,
      required: false,
      default: '',
    },
    url: {
      type: String,
      required: false,
      default: '',
    },
    embeddable: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    httpLabel() {
      const protocol = this.httpUrl ? getHTTPProtocol(this.httpUrl)?.toUpperCase() : '';
      return sprintf(__('Clone with %{protocol}'), { protocol });
    },
    sections() {
      const sections = [
        { label: __('Clone with SSH'), link: this.sshUrl, testId: 'copy-ssh-url' },
        { label: this.httpLabel, link: this.httpUrl, testId: 'copy-http-url' },
      ];

      if (this.kerberosUrl) {
        sections.push({
          label: __('Clone with KRB5'),
          link: this.kerberosUrl,
          testId: 'copy-kerberos-url',
        });
      }

      if (this.embeddable && this.url) {
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
    <code-dropdown-clone-item
      v-for="{ label, link, testId } in sections"
      :key="label"
      :label="label"
      :link="link"
      :test-id="`${testId}-button`"
      :data-testid="testId"
    />
  </gl-disclosure-dropdown>
</template>
