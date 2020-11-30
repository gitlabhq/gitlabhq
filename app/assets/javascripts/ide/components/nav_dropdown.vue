<script>
import $ from 'jquery';
import { mapGetters } from 'vuex';
import NavForm from './nav_form.vue';
import NavDropdownButton from './nav_dropdown_button.vue';

export default {
  components: {
    NavDropdownButton,
    NavForm,
  },
  data() {
    return {
      isVisibleDropdown: false,
    };
  },
  computed: {
    ...mapGetters(['canReadMergeRequests']),
  },
  mounted() {
    this.addDropdownListeners();
  },
  beforeDestroy() {
    this.removeDropdownListeners();
  },
  methods: {
    addDropdownListeners() {
      $(this.$refs.dropdown)
        .on('show.bs.dropdown', () => this.showDropdown())
        .on('hide.bs.dropdown', () => this.hideDropdown());
    },
    removeDropdownListeners() {
      $(this.$refs.dropdown)
        .off('show.bs.dropdown')
        .off('hide.bs.dropdown');
    },
    showDropdown() {
      this.isVisibleDropdown = true;
    },
    hideDropdown() {
      this.isVisibleDropdown = false;
    },
  },
};
</script>

<template>
  <div ref="dropdown" class="btn-group ide-nav-dropdown dropdown" data-testid="ide-nav-dropdown">
    <nav-dropdown-button :show-merge-requests="canReadMergeRequests" />
    <div class="dropdown-menu dropdown-menu-left p-0">
      <nav-form v-if="isVisibleDropdown" :show-merge-requests="canReadMergeRequests" />
    </div>
  </div>
</template>
