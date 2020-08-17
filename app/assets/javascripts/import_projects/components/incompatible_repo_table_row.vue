<script>
import { GlIcon, GlBadge } from '@gitlab/ui';

export default {
  components: {
    GlBadge,
    GlIcon,
  },
  props: {
    repo: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <tr class="import-row">
    <td>
      <a :href="repo.importSource.providerLink" rel="noreferrer noopener" target="_blank"
        >{{ repo.importSource.fullName }}
        <gl-icon v-if="repo.importSource.providerLink" name="external-link" />
      </a>
    </td>
    <td></td>
    <td></td>
    <td>
      <gl-badge variant="danger">{{ __('Incompatible project') }}</gl-badge>
    </td>
  </tr>
</template>
