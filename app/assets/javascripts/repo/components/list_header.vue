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
    <button
      type="button"
      class="btn btn-default btn-sm js-download-btn"
      data-toggle="dropdown"
      data-target=".js-download-dropdown"
      :aria-label="__('Select Archive Format')"
    >
      <i
        class="fa fa-download"
        aria-hidden="true"
      >
      </i>
      <i
        class="fa fa-caret-down"
        aria-hidden="true"
      >
      </i>
    </button>
    <aside
      v-if="canCommit"
      class="pull-right"
    >
      <button
        type="button"
        class="btn btn-transparent btn-sm cdark"
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
        class="btn btn-transparent btn-sm cdark"
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
