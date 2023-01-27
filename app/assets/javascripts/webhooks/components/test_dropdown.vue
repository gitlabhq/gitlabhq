<script>
import { GlDisclosureDropdown } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'HookTestDropdown',
  components: {
    GlDisclosureDropdown,
  },
  props: {
    items: {
      type: Array,
      required: true,
    },
    size: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  computed: {
    itemsWithAction() {
      return this.items.map((item) => ({
        text: item.text,
        action: () => this.testHook(item.href),
      }));
    },
  },
  methods: {
    testHook(href) {
      // HACK: Trigger @rails/ujs's data-method handling.
      //
      // The more obvious approaches of (1) declaratively rendering the
      // links using GlDisclosureDropdown's list-item slot and (2) using
      // item.extraAttrs to set the data-method attributes on the links
      // do not work for reasons laid out in
      // https://gitlab.com/gitlab-org/gitlab-ui/-/issues/2134.
      //
      // Sending the POST with axios also doesn't work, since the
      // endpoints return 302 redirects. Since axios uses XMLHTTPRequest,
      // it transparently follows redirects, meaning the Location header
      // of the first response cannot be inspected/acted upon by JS. We
      // could manually trigger a reload afterwards, but that would mean
      // a duplicate fetch of the current page: one by the XHR, and one
      // by the explicit reload. It would also mean losing the flash
      // alert set by the backend, making the feature useless for the
      // user.
      //
      // The ideal fix here would be to refactor the test endpoint to
      // return a JSON response, removing the need for a redirect/page
      // reload to show the result.
      const a = document.createElement('a');
      a.setAttribute('hidden', '');
      a.href = href;
      a.dataset.method = 'post';
      document.body.appendChild(a);
      a.click();
      a.remove();
    },
  },
  i18n: {
    test: __('Test'),
  },
};
</script>

<template>
  <gl-disclosure-dropdown :toggle-text="$options.i18n.test" :items="itemsWithAction" :size="size" />
</template>
