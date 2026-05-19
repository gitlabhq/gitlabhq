<script>
import { GlBadge, GlFormCheckbox, GlButton, GlLink, GlPopover, GlSprintf } from '@gitlab/ui';
import { keyBy, xor } from 'lodash-es';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __, s__ } from '~/locale';

const SCOPE_API = 'api';

const SCOPE_CATEGORIES = [
  { label: '', scopes: [SCOPE_API, 'read_api'] },
  { label: __('AI'), scopes: ['ai_features'] },
  { label: __('Repository'), scopes: ['read_repository', 'write_repository'] },
  {
    label: s__('VirtualRegistry|Registry'),
    scopes: ['read_virtual_registry', 'write_virtual_registry'],
  },
  { label: s__('Runners|Runners'), scopes: ['create_runner', 'manage_runner'] },
  { label: s__('AccessTokens|Service ping'), scopes: ['read_service_ping'] },
  {
    label: s__('AccessTokens|User & Administration'),
    scopes: ['read_user', 'self_rotate', 'k8s_proxy', 'admin_mode', 'sudo'],
  },
];

export default {
  name: 'ScopeSelector',
  components: { GlBadge, GlFormCheckbox, GlButton, GlLink, GlPopover, GlSprintf },
  model: {
    prop: 'selectedScopes',
    event: 'change',
  },
  props: {
    availableScopes: {
      type: Array,
      required: true,
    },
    selectedScopes: {
      type: Array,
      required: true,
    },
    isValid: {
      type: Boolean,
      required: true,
    },
    newGranularPatPath: {
      type: String,
      required: true,
    },
  },
  emits: ['change'],
  computed: {
    categorizedScopes() {
      const lookup = keyBy(this.availableScopes, 'value');

      const categories = SCOPE_CATEGORIES.map(({ label, scopes }) => ({
        label,
        // Convert the list of scope keys (['api', 'read_api']) to the scope objects from availableScopes.
        scopes: scopes.map((scope) => lookup[scope]).filter(Boolean),
      }));

      // Get a list of unknown scopes from availableScopes (if any) and add them to an Other category.
      const knownScopes = new Set(SCOPE_CATEGORIES.flatMap(({ scopes }) => scopes));
      const unknownScopes = this.availableScopes.filter(({ value }) => !knownScopes.has(value));
      if (unknownScopes.length > 0) {
        categories.push({ label: __('Other'), scopes: unknownScopes });
      }

      // Only return categories with at least 1 scope.
      return categories.filter(({ scopes }) => scopes.length > 0);
    },
    isApiScopeSelected() {
      return this.selectedScopes.includes(SCOPE_API);
    },
  },
  methods: {
    getScopeId(scope) {
      return `scope-${scope}`;
    },
    isApiScope(scope) {
      return scope === SCOPE_API;
    },
    isScopeDisabled(scope) {
      return this.isApiScopeSelected && !this.isApiScope(scope);
    },
    toggleScope(scope) {
      // The API scope covers every scope, so if it's selected, all other scopes should be unselected.
      if (this.isApiScope(scope)) {
        this.$emit('change', this.selectedScopes.includes(SCOPE_API) ? [] : [SCOPE_API]);
      } else {
        this.$emit('change', xor(this.selectedScopes, [scope]));
      }
    },
  },
  scopesHelpPagePath: helpPagePath('user/profile/personal_access_tokens', {
    anchor: 'personal-access-token-scopes',
  }),
};
</script>

<template>
  <div>
    <h2 class="gl-heading-3 gl-mb-2 gl-mt-7">{{ s__('AccessTokens|Set token scope') }}</h2>
    <p class="gl-mb-4 gl-text-subtle" :class="{ '!gl-mb-3': !isValid }">
      <gl-sprintf
        :message="
          s__(
            'AccessTokens|Scopes set the permission levels granted to the token. %{linkStart}Learn more%{linkEnd}.',
          )
        "
      >
        <template #link="{ content }">
          <gl-link :href="$options.scopesHelpPagePath" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>

    <p v-if="!isValid" class="gl-text-danger" data-testid="error-message">
      {{ s__('AccessTokens|At least one scope is required.') }}
    </p>

    <fieldset v-for="category in categorizedScopes" :key="category.label">
      <legend class="gl-mb-4 gl-border-none gl-text-base gl-font-bold">
        {{ category.label }}
      </legend>

      <ul class="gl-list-none gl-p-0">
        <li v-for="scope in category.scopes" :key="scope.value" :data-testid="scope.value">
          <gl-form-checkbox
            :checked="selectedScopes.includes(scope.value)"
            :disabled="isScopeDisabled(scope.value)"
            class="gl-mb-2 gl-ml-5 gl-inline-block"
            @change="toggleScope(scope.value)"
          >
            {{ scope.value }}
          </gl-form-checkbox>

          <gl-button
            :id="getScopeId(scope.value)"
            icon="information-o"
            category="tertiary"
            class="gl-ml-2 !gl-min-h-0 !gl-min-w-0 !gl-border-none !gl-bg-transparent gl-align-text-bottom"
            :aria-label="scope.text"
          />
          <gl-popover
            :target="getScopeId(scope.value)"
            triggers="focus"
            :title="scope.value"
            placement="auto"
            :show-close-button="true"
            :delay="0"
          >
            {{ scope.text }}

            <p v-if="isApiScope(scope.value)" class="gl-mb-0 gl-mt-2">
              <gl-sprintf
                :message="
                  s__(
                    'AccessTokens|To limit access, use a %{linkStart}fine-grained personal access token%{linkEnd} instead.',
                  )
                "
              >
                <template #link="{ content }">
                  <gl-link :href="newGranularPatPath">{{ content }}</gl-link>
                </template>
              </gl-sprintf>
            </p>
          </gl-popover>

          <gl-badge
            v-if="isApiScope(scope.value) && isApiScopeSelected"
            icon="warning"
            variant="warning"
            class="gl-ml-2 gl-align-sub"
          >
            {{ s__('AccessTokens|Broad access') }}
          </gl-badge>
        </li>
      </ul>
    </fieldset>
  </div>
</template>
