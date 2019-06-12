<script>
import { GlButton } from '@gitlab/ui';
import Icon from './icon.vue';

export default {
  components: {
    Icon,
    GlButton,
  },
  props: {
    size: {
      type: String,
      required: false,
      default: '',
    },
    primaryButtonClass: {
      type: String,
      required: false,
      default: '',
    },
    dropdownClass: {
      type: String,
      required: false,
      default: '',
    },
    actions: {
      type: Array,
      required: true,
    },
    defaultAction: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      selectedAction: this.defaultAction,
    };
  },
  computed: {
    selectedActionTitle() {
      return this.actions[this.selectedAction].title;
    },
    buttonSizeClass() {
      return `btn-${this.size}`;
    },
  },
  methods: {
    handlePrimaryActionClick() {
      this.$emit('onActionClick', this.actions[this.selectedAction]);
    },
    handleActionClick(selectedAction) {
      this.selectedAction = selectedAction;
      this.$emit('onActionSelect', selectedAction);
    },
  },
};
</script>

<template>
  <div class="btn-group droplab-dropdown comment-type-dropdown">
    <gl-button :class="primaryButtonClass" :size="size" @click.prevent="handlePrimaryActionClick">
      {{ selectedActionTitle }}
    </gl-button>
    <button
      :class="buttonSizeClass"
      type="button"
      class="btn dropdown-toggle pl-2 pr-2"
      data-display="static"
      data-toggle="dropdown"
    >
      <icon name="arrow-down" aria-label="toggle dropdown" />
    </button>
    <ul :class="dropdownClass" class="dropdown-menu dropdown-open-top">
      <template v-for="(action, index) in actions">
        <li :key="index" :class="{ 'droplab-item-selected': selectedAction === index }">
          <gl-button class="btn-transparent" @click.prevent="handleActionClick(index)">
            <i aria-hidden="true" class="fa fa-check icon"> </i>
            <div class="description">
              <strong>{{ action.title }}</strong>
              <p>{{ action.description }}</p>
            </div>
          </gl-button>
        </li>
        <li v-if="index === 0" :key="`${index}-separator`" class="divider droplab-item-ignore"></li>
      </template>
    </ul>
  </div>
</template>
