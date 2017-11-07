<script>
  import { mapState } from 'vuex';

  export default {
    computed: {
      ...mapState([
        'downloads',
      ]),
    },
  };
</script>

<template>
  <div class="js-download-dropdown">
    <ul
      class="dropdown-menu download-dropdown-menu"
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
</template>
