<script>
import { mapState, mapActions } from 'vuex';
import LegacyCiVariableModal from './legacy_ci_variable_modal.vue';
import LegacyCiVariableTable from './legacy_ci_variable_table.vue';

export default {
  components: {
    LegacyCiVariableModal,
    LegacyCiVariableTable,
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
      <legacy-ci-variable-table />
      <legacy-ci-variable-modal />
    </div>
  </div>
</template>
