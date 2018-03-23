<script>
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
  },
  props: {
    hasChanges: {
      type: Boolean,
      required: false,
      default: false,
    },
    hasMergeRequest: {
      type: Boolean,
      required: false,
      default: false,
    },
    viewer: {
      type: String,
      required: true,
    },
    showShadow: {
      type: Boolean,
      required: true,
    },
  },
  methods: {
    changeMode(mode) {
      this.$emit('click', mode);
    },
  },
};
</script>

<template>
  <div
    class="dropdown"
    :class="{
      shadow: showShadow,
    }"
  >
    <button
      type="button"
      class="btn btn-primary btn-sm"
      :class="{
        'btn-inverted': hasChanges,
      }"
      data-toggle="dropdown"
    >
      <template v-if="viewer === 'mrdiff'">
        {{ __('Reviewing (merge request)') }}
      </template>
      <template v-else-if="viewer === 'editor'">
        {{ __('Editing') }}
      </template>
      <template v-else>
        {{ __('Reviewing') }}
      </template>
      <icon
        name="angle-down"
        :size="12"
        css-classes="caret-down"
      />
    </button>
    <div class="dropdown-menu dropdown-menu-selectable dropdown-open-left">
      <ul>
        <li v-if="hasMergeRequest">
          <a
            href="#"
            @click.prevent="changeMode('mrdiff')"
            :class="{
              'is-active': viewer === 'mrdiff',
            }"
          >
            <strong class="dropdown-menu-inner-title">{{ __('Reviewing (merge request)') }}</strong>
            <span class="dropdown-menu-inner-content">
              {{ __('Compare changes of the merge request') }}
            </span>
          </a>
        </li>
        <li v-if="hasMergeRequest" role="separator" class="divider"></li>
        <li>
          <a
            href="#"
            @click.prevent="changeMode('editor')"
            :class="{
              'is-active': viewer === 'editor',
            }"
          >
            <strong class="dropdown-menu-inner-title">{{ __('Editing') }}</strong>
            <span class="dropdown-menu-inner-content">
              {{ __('View and edit lines') }}
            </span>
          </a>
        </li>
        <li>
          <a
            href="#"
            @click.prevent="changeMode('diff')"
            :class="{
              'is-active': viewer === 'diff',
            }"
          >
            <strong class="dropdown-menu-inner-title">{{ __('Reviewing') }}</strong>
            <span class="dropdown-menu-inner-content">
              {{ __('Compare changes with the last commit') }}
            </span>
          </a>
        </li>
      </ul>
    </div>
  </div>
</template>
