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
      <a :href="repo.providerLink" rel="noreferrer noopener" target="_blank">
        {{ repo.fullName }}
        <gl-icon v-if="repo.providerLink" name="external-link" />
      </a>
    </td>
    <td></td>
    <td></td>
    <td>
      <gl-badge variant="danger">{{ __('Incompatible project') }}</gl-badge>
    </td>
  </tr>
</template>
