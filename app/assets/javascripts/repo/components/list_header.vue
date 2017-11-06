<script>
  import { mapActions, mapState } from 'vuex';

  export default {
    computed: {
      ...mapState([
        'canCommit',
        'downloads',
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
    <div class="project-action-button dropdown inline">
      <button
        type="button"
        class="btn btn default"
        data-toggle="dropdown"
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
      <ul
        class="dropdown-menu"
        role="menu"
      >
        <template v-for="(data, key) in downloads">
          <li class="dropdown-header">
            {{ key }}
          </li>
          <li v-for="download in data">
            <a
              :href="download.link"
              rel="nofollow"
              download
            >
              {{ download.text }}
            </a>
          </li>
        </template>
      </ul>
    </div>
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
