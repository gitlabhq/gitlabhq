<script>
import { GlButton } from '@gitlab/ui';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import { s__, __ } from '~/locale';
import InputCopyToggleVisibility from '~/vue_shared/components/input_copy_toggle_visibility/input_copy_toggle_visibility.vue';

export default {
  name: 'CreatedPersonalAccessToken',
  components: {
    PageHeading,
    CrudComponent,
    InputCopyToggleVisibility,
    GlButton,
  },
  inject: ['accessTokenTableUrl'],
  props: {
    value: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      copied: false,
    };
  },
  computed: {
    formInputGroupProps() {
      return {
        'data-testid': this.$options.inputId,
        autocomplete: 'off', // Avoids the revealed token to be added to the search field
      };
    },
  },
  methods: {
    handleCopy() {
      this.copied = true;
    },
  },
  i18n: {
    heading: s__('AccessTokens|Your new token has been created'),
    description: s__(
      "AccessTokens|Make sure you copy your token - you won't be able to access it again.",
    ),
    label: s__('AccessTokens|Token details'),
    done: __('Done'),
  },
  inputId: 'created-personal-access-token-field',
};
</script>

<template>
  <div>
    <page-heading :heading="$options.i18n.heading" />

    <crud-component :title="$options.i18n.label">
      <p class="gl-text-subtle">
        {{ $options.i18n.description }}
      </p>

      <input-copy-toggle-visibility
        :show-copy-button="true"
        :aria-label="$options.i18n.label"
        :label-for="$options.inputId"
        :value="value"
        :form-input-group-props="formInputGroupProps"
        readonly
        size="xl"
        class="gl-mb-0"
        @copied="handleCopy"
      />
    </crud-component>

    <div class="gl-mt-4 gl-flex gl-gap-3">
      <gl-button variant="confirm" :href="accessTokenTableUrl" :disabled="!copied">
        {{ $options.i18n.done }}
      </gl-button>
    </div>
  </div>
</template>
