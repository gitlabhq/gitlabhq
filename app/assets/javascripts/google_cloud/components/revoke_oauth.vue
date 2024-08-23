<script>
import { GlButton, GlForm } from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';
import { s__ } from '~/locale';

export const GOOGLE_CLOUD_REVOKE_TITLE = s__('GoogleCloud|Revoke authorizations');
export const GOOGLE_CLOUD_REVOKE_DESCRIPTION = s__(
  'GoogleCloud|Revoke authorizations granted to GitLab. This does not invalidate service accounts.',
);

export default {
  components: { GlButton, GlForm },
  csrf,
  props: {
    url: {
      type: String,
      required: true,
    },
  },
  i18n: {
    title: GOOGLE_CLOUD_REVOKE_TITLE,
    description: GOOGLE_CLOUD_REVOKE_DESCRIPTION,
  },
};
</script>

<template>
  <div class="gl-mx-4">
    <h2 class="gl-text-size-h2">{{ $options.i18n.title }}</h2>
    <p>{{ $options.i18n.description }}</p>
    <gl-form :action="url" method="post">
      <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
      <gl-button category="secondary" variant="danger" type="submit">
        {{ $options.i18n.title }}
      </gl-button>
    </gl-form>
  </div>
</template>
