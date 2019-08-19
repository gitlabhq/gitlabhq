<script>
import StageCardListItem from './stage_card_list_item.vue';

export default {
  name: 'StageNavItem',
  components: {
    StageCardListItem,
  },
  props: {
    isDefaultStage: {
      type: Boolean,
      default: false,
      required: false,
    },
    isActive: {
      type: Boolean,
      default: false,
      required: false,
    },
    isUserAllowed: {
      type: Boolean,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    value: {
      type: String,
      default: '',
      required: false,
    },
    canEdit: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  computed: {
    hasValue() {
      return this.value && this.value.length > 0;
    },
    editable() {
      return this.isUserAllowed && this.canEdit;
    },
  },
};
</script>

<template>
  <li @click="$emit('select')">
    <stage-card-list-item :is-active="isActive" :can-edit="editable">
      <div class="stage-nav-item-cell stage-name p-0" :class="{ 'font-weight-bold': isActive }">
        {{ title }}
      </div>
      <div class="stage-nav-item-cell stage-median mr-4">
        <template v-if="isUserAllowed">
          <span v-if="hasValue">{{ value }}</span>
          <span v-else class="stage-empty">{{ __('Not enough data') }}</span>
        </template>
        <template v-else>
          <span class="not-available">{{ __('Not available') }}</span>
        </template>
      </div>
      <template v-slot:dropdown-options>
        <template v-if="isDefaultStage">
          <li>
            <button type="button" class="btn-default btn-transparent">
              {{ __('Hide stage') }}
            </button>
          </li>
        </template>
        <template v-else>
          <li>
            <button type="button" class="btn-default btn-transparent">
              {{ __('Edit stage') }}
            </button>
          </li>
          <li>
            <button type="button" class="btn-danger danger">
              {{ __('Remove stage') }}
            </button>
          </li>
        </template>
      </template>
    </stage-card-list-item>
  </li>
</template>
