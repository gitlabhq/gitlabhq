<script>
import { mapGetters, mapActions, mapState } from 'vuex';
import modal from '~/vue_shared/components/modal.vue';

export default {
  components: {
    modal,
  },
  computed: {
    ...mapState([
      'editMode',
    ]),
    ...mapGetters([
      'canEditFile',
    ]),
    buttonLabel() {
      return this.editMode ? this.__('Cancel edit') : this.__('Edit');
    },
  },
  methods: {
    ...mapActions([
      'toggleEditMode',
    ]),
  },
};
</script>

<template>
  <div class="editable-mode">
    <button
      v-if="canEditFile"
      class="btn btn-default"
      type="button"
      @click.prevent="toggleEditMode()">
      <i
        v-if="!editMode"
        class="fa fa-pencil"
        aria-hidden="true">
      </i>
      <span>
        {{ buttonLabel }}
      </span>
    </button>
  </div>
</template>
