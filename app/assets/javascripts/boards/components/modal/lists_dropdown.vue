<script>
import { GlLink } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import ModalStore from '../../stores/modal_store';
import boardsStore from '../../stores/boards_store';

export default {
  components: {
    GlLink,
    Icon,
  },
  data() {
    return {
      modal: ModalStore.store,
      state: boardsStore.state,
    };
  },
  computed: {
    selected() {
      return this.modal.selectedList || this.state.lists[1];
    },
  },
  destroyed() {
    this.modal.selectedList = null;
  },
};
</script>
<template>
  <div class="dropdown inline">
    <button class="dropdown-menu-toggle" type="button" data-toggle="dropdown" aria-expanded="false">
      <span :style="{ backgroundColor: selected.label.color }" class="dropdown-label-box"> </span>
      {{ selected.title }} <icon name="chevron-down" />
    </button>
    <div class="dropdown-menu dropdown-menu-selectable dropdown-menu-drop-up">
      <ul>
        <li v-for="(list, i) in state.lists" v-if="list.type == 'label'" :key="i">
          <gl-link
            :class="{ 'is-active': list.id == selected.id }"
            href="#"
            role="button"
            @click.prevent="modal.selectedList = list"
          >
            <span :style="{ backgroundColor: list.label.color }" class="dropdown-label-box"> </span>
            {{ list.title }}
          </gl-link>
        </li>
      </ul>
    </div>
  </div>
</template>
