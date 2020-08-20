<script>
import { mapState, mapActions } from 'vuex';
import CiVariableModal from './ci_variable_modal.vue';
import CiVariableTable from './ci_variable_table.vue';

export default {
  components: {
    CiVariableModal,
    CiVariableTable,
  },
  computed: {
    ...mapState(['isGroup']),
  },
  mounted() {
    if (!this.isGroup) {
      this.fetchEnvironments();
    }
  },
  methods: {
    ...mapActions(['fetchEnvironments']),
  },
};
</script>

<template>
  <div class="row">
    <div class="col-lg-12">
      <ci-variable-table />
      <ci-variable-modal />
    </div>
  </div>
</template>
