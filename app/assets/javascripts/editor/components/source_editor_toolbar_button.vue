<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import updateToolbarItemMutation from '~/editor/graphql/update_item.mutation.graphql';
import getToolbarItemQuery from '~/editor/graphql/get_item.query.graphql';

export default {
  name: 'SourceEditorToolbarButton',
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    button: {
      type: Object,
      required: false,
      default() {
        return {};
      },
    },
  },
  data() {
    return {
      buttonItem: this.button,
    };
  },
  apollo: {
    buttonItem: {
      query: getToolbarItemQuery,
      variables() {
        return {
          id: this.button.id,
        };
      },
      update({ item }) {
        return item;
      },
      skip() {
        return !this.button.id;
      },
    },
  },
  computed: {
    icon() {
      return this.buttonItem.selected
        ? this.buttonItem.selectedIcon || this.buttonItem.icon
        : this.buttonItem.icon;
    },
    label() {
      return this.buttonItem.selected
        ? this.buttonItem.selectedLabel || this.buttonItem.label
        : this.buttonItem.label;
    },
  },
  methods: {
    clickHandler() {
      if (this.buttonItem.onClick) {
        this.buttonItem.onClick();
      }
      this.$apollo.mutate({
        mutation: updateToolbarItemMutation,
        variables: {
          id: this.buttonItem.id,
          propsToUpdate: {
            selected: !this.buttonItem.selected,
          },
        },
      });
      this.$emit('click');
    },
  },
};
</script>
<template>
  <div>
    <gl-button
      v-gl-tooltip.hover
      :category="buttonItem.category"
      :variant="buttonItem.variant"
      type="button"
      :selected="buttonItem.selected"
      :icon="icon"
      :title="label"
      :aria-label="label"
      @click="clickHandler"
    />
  </div>
</template>
