<script>
import { GlButton } from '@gitlab/ui';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import InputCopyToggleVisibility from '~/vue_shared/components/input_copy_toggle_visibility/input_copy_toggle_visibility.vue';

export default {
  name: 'CreatedPersonalAccessToken',
  components: {
    PageHeading,
    CrudComponent,
    InputCopyToggleVisibility,
    GlButton,
  },
  props: {
    token: {
      type: String,
      required: true,
    },
    href: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      copied: false,
    };
  },
};
</script>

<template>
  <div>
    <page-heading :heading="s__('AccessTokens|Your new token has been created')" />

    <crud-component :title="s__('AccessTokens|Token details')" class="gl-mb-4">
      <p class="gl-text-subtle">
        {{
          s__("AccessTokens|Make sure you copy your token - you won't be able to access it again.")
        }}
      </p>
      <input-copy-toggle-visibility
        :value="token"
        readonly
        size="xl"
        class="gl-mb-0"
        @copied="copied = true"
      />
    </crud-component>

    <gl-button variant="confirm" :href="href" :disabled="!copied">
      {{ __('Done') }}
    </gl-button>
  </div>
</template>
