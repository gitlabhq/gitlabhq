<script>
import { mapState } from 'vuex';
import { s__, sprintf } from '~/locale';

export default {
  components: {},
  computed: {
    ...mapState({
      helpPagePath: 'helpPagePath',
    }),

    helpText() {
      return sprintf(
        s__(
          'PackageRegistry|Read more about the %{helpLinkStart}Container Registry tag retention policies%{helpLinkEnd}',
        ),
        {
          helpLinkStart: `<a href="${this.helpPagePath}" target="_blank">`,
          helpLinkEnd: '</a>',
        },
        false,
      );
    },
  },
};
</script>

<template>
  <div>
    <p>
      {{ s__('PackageRegistry|Tag retention policies are designed to:') }}
    </p>
    <ul>
      <li>{{ s__('PackageRegistry|Keep and protect the images that matter most.') }}</li>
      <li>
        {{
          s__("PackageRegistry|Automatically remove extra images that aren't designed to be kept.")
        }}
      </li>
    </ul>
    <p ref="help-link" v-html="helpText"></p>
  </div>
</template>
