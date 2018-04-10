<script>
import Icon from '~/vue_shared/components/icon.vue';
import { __, sprintf } from '~/locale';

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
    mergeRequestId: {
      type: String,
      required: false,
      default: '',
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
  computed: {
    mergeReviewLine() {
      return sprintf(__('Reviewing (merge request !%{mergeRequestId})'), {
        mergeRequestId: this.mergeRequestId,
      });
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
      <template v-if="viewer === 'mrdiff' && mergeRequestId">
        {{ mergeReviewLine }}
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
        <template v-if="mergeRequestId">
          <li>
            <a
              href="#"
              @click.prevent="changeMode('mrdiff')"
              :class="{
                'is-active': viewer === 'mrdiff',
              }"
            >
              <strong class="dropdown-menu-inner-title">
                {{ mergeReviewLine }}
              </strong>
              <span class="dropdown-menu-inner-content">
                {{ __('Compare changes with the merge request target branch') }}
              </span>
            </a>
          </li>
          <li
            role="separator"
            class="divider"
          >
          </li>
        </template>
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
