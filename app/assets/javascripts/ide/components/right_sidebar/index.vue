<script>
import tooltip from '../../../vue_shared/directives/tooltip';
import Icon from '../../../vue_shared/components/icon.vue';
import Pipelines from './pipelines.vue';

export default {
  directives: {
    tooltip,
  },
  components: {
    Icon,
    Pipelines,
  },
};
</script>

<template>
  <div
    class="multi-file-commit-panel ide-right-sidebar"
  >
    <div class="multi-file-commit-panel-inner">
      <pipelines />
    </div>
    <nav class="ide-activity-bar">
      <ul class="list-unstyled">
        <li v-once>
          <a
            v-tooltip
            data-container="body"
            data-placement="left"
            :title="__('Pipelines')"
            class="ide-sidebar-link"
            href="a"
          >
            <icon
              :size="16"
              name="log"
            />
          </a>
        </li>
      </ul>
    </nav>
  </div>
</template>

<style>
.ide-right-sidebar {
  width: auto;
  min-width: 60px;
}

.ide-right-sidebar .ide-activity-bar {
  border-left: 1px solid #eaeaea;
}

.ide-right-sidebar .multi-file-commit-panel-inner {
  width: 300px;
  background-color: #fff;
  border-left: 1px solid #eaeaea;
}
</style>
