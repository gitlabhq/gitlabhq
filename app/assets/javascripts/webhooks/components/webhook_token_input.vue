<script>
import { GlAlert, GlButton, GlFormGroup, GlFormInput, GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

const STATE_NO_TOKEN = 'no_token';
const STATE_TOKEN_REVEALED = 'token_revealed';
const STATE_TOKEN_HIDDEN = 'token_hidden';

export default {
  name: 'WebhookTokenInput',
  components: {
    GlAlert,
    GlButton,
    GlFormGroup,
    GlFormInput,
    GlLink,
    GlSprintf,
    ClipboardButton,
  },
  props: {
    hasExistingToken: {
      type: Boolean,
      required: false,
      default: false,
    },
    inputName: {
      type: String,
      required: false,
      default: 'hook[signing_token]',
    },
    docsPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      tokenState: this.hasExistingToken ? STATE_TOKEN_HIDDEN : STATE_NO_TOKEN,
      hadExistingToken: this.hasExistingToken,
      tokenValue: '',
      isMasked: false,
    };
  },
  computed: {
    isNoToken() {
      return this.tokenState === STATE_NO_TOKEN;
    },
    isTokenRevealed() {
      return this.tokenState === STATE_TOKEN_REVEALED;
    },
    isRegeneration() {
      return this.hadExistingToken && this.isTokenRevealed;
    },
    inputType() {
      return this.isMasked ? 'password' : 'text';
    },
    toggleIcon() {
      return this.isMasked ? 'eye' : 'eye-slash';
    },
    toggleAriaLabel() {
      return this.isMasked ? s__('Webhooks|Show token') : s__('Webhooks|Hide token');
    },
  },
  methods: {
    generateToken() {
      const bytes = new Uint8Array(32);
      window.crypto.getRandomValues(bytes);
      const base64 = btoa(String.fromCharCode(...bytes));
      this.tokenValue = `whsec_${base64}`;
      this.isMasked = false;
    },
    handleGenerate() {
      this.generateToken();
      this.tokenState = STATE_TOKEN_REVEALED;
    },
    handleRegenerate() {
      this.handleGenerate();
    },
    toggleMask() {
      this.isMasked = !this.isMasked;
    },
  },
  TOKEN_MASK: '\u2022'.repeat(30),
  i18n: {
    title: s__('Webhooks|Signing token'),
    description: s__(
      'Webhooks|Used to validate requests from GitLab. Sent in the %{codeStart}webhook-signature%{codeEnd} HTTP header. %{linkStart}How to use a signing token?%{linkEnd}',
    ),
    generateButton: s__('Webhooks|Generate signing token'),
    warningNew: s__('Webhooks|Save this token now because you can only access it once.'),
    warningRegenerated: s__(
      "Webhooks|Save this token now because you can only access it once. After you save this form, any apps that rely on the previous token won't work until you replace it with this token.",
    ),
    cannotAccess: s__('Webhooks|You cannot access the token unless you regenerate it.'),
    copy: s__('Webhooks|Copy token'),
    regenerate: s__('Webhooks|Regenerate token'),
    formatHint: s__(
      'Webhooks|Must start with %{codeStart}whsec_%{codeEnd} followed by a base64-encoded 32-byte key.',
    ),
  },
};
</script>

<template>
  <gl-form-group :label="$options.i18n.title" label-for="webhook-signing-token">
    <p class="gl-mb-3">
      <gl-sprintf :message="$options.i18n.description">
        <template #code="{ content }">
          <code>{{ content }}</code>
        </template>
        <template #link="{ content }">
          <gl-link :href="docsPath" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>

    <!-- no_token: generate button -->
    <gl-button
      v-if="isNoToken"
      variant="default"
      data-testid="generate-signing-token-button"
      @click="handleGenerate"
    >
      {{ $options.i18n.generateButton }}
    </gl-button>

    <!-- token_revealed: orange warning alert with input and action buttons -->
    <gl-alert
      v-else-if="isTokenRevealed"
      variant="warning"
      :dismissible="false"
      class="gl-mb-0"
      data-testid="signing-token-revealed"
    >
      <p class="gl-mb-3">
        {{ isRegeneration ? $options.i18n.warningRegenerated : $options.i18n.warningNew }}
      </p>
      <div class="gl-flex gl-flex-wrap gl-items-center gl-gap-2">
        <gl-form-input
          id="webhook-signing-token"
          v-model="tokenValue"
          :name="inputName"
          :type="inputType"
          autocomplete="new-password"
          class="gl-form-input-xl"
          data-testid="webhook-signing-token-input"
        />
        <gl-button
          category="tertiary"
          :icon="toggleIcon"
          :aria-label="toggleAriaLabel"
          :title="toggleAriaLabel"
          data-testid="toggle-visibility-button"
          @click="toggleMask"
        />
        <clipboard-button
          :text="tokenValue"
          :title="$options.i18n.copy"
          category="tertiary"
          data-testid="clipboard-button"
        />
        <gl-button
          category="tertiary"
          icon="retry"
          :aria-label="$options.i18n.regenerate"
          :title="$options.i18n.regenerate"
          data-testid="regenerate-token-button"
          @click="handleRegenerate"
        />
      </div>
      <p class="gl-mt-2 gl-text-subtle" data-testid="signing-token-format-hint">
        <gl-sprintf :message="$options.i18n.formatHint">
          <template #code="{ content }"
            ><code>{{ content }}</code></template
          >
        </gl-sprintf>
      </p>
    </gl-alert>

    <!-- token_hidden: masked dots with only a regenerate button; token is NOT submitted -->
    <div v-else data-testid="signing-token-hidden">
      <div class="gl-flex gl-items-center gl-gap-2">
        <span class="gl-text-xl gl-tracking-widest" aria-hidden="true">
          {{ $options.TOKEN_MASK }}
        </span>
        <gl-button
          category="tertiary"
          icon="retry"
          :aria-label="$options.i18n.regenerate"
          :title="$options.i18n.regenerate"
          data-testid="regenerate-token-button"
          @click="handleRegenerate"
        />
      </div>
      <p class="gl-mt-2 gl-text-subtle">{{ $options.i18n.cannotAccess }}</p>
    </div>
  </gl-form-group>
</template>
