<script>
import { GlBadge } from '@gitlab/ui';

export default {
  components: {
    GlBadge,
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
      </a>
    </td>
    <td></td>
    <td></td>
    <td>
      <gl-badge variant="danger">{{ __('Incompatible project') }}</gl-badge>
    </td>
  </tr>
</template>
