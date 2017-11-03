<script>
  import { mapActions, mapState } from 'vuex';

  export default {
    computed: {
      ...mapState([
        'canCommit',
      ]),
    },
    methods: {
      ...mapActions([
        'openNewEntryModal',
      ]),
    },
  };
</script>

<template>
  <header class="clearfix multi-file-list-header">
    <aside
      v-if="canCommit"
      class="pull-right"
    >
      <button
        type="button"
        class="btn btn-transparent cdark"
        :aria-label="__('Create new file')"
        @click="openNewEntryModal('blob')"
      >
        <i
          class="fa fa-file-o"
          aria-hidden="true"
        >
        </i>
      </button>
      <button
        type="button"
        class="btn btn-transparent cdark"
        :aria-label="__('Create new directory')"
        @click="openNewEntryModal('tree')"
      >
        <i
          class="fa fa-folder-o"
          aria-hidden="true"
        >
        </i>
      </button>
    </aside>
  </header>
</template>
