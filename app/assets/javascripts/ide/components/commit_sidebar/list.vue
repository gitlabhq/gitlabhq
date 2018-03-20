<script>
  import { mapState } from 'vuex';
  import icon from '~/vue_shared/components/icon.vue';
  import listItem from './list_item.vue';
  import listCollapsed from './list_collapsed.vue';

  export default {
    components: {
      icon,
      listItem,
      listCollapsed,
    },
    props: {
      title: {
        type: String,
        required: true,
      },
      fileList: {
        type: Array,
        required: true,
      },
    },
    computed: {
      ...mapState([
        'currentProjectId',
        'currentBranchId',
        'rightPanelCollapsed',
      ]),
      isCommitInfoShown() {
        return this.rightPanelCollapsed || this.fileList.length;
      },
    },
    methods: {
      toggleCollapsed() {
        this.$emit('toggleCollapsed');
      },
    },
  };
</script>

<template>
  <div
    :class="{
      'multi-file-commit-list': isCommitInfoShown
    }"
  >
    <list-collapsed
      v-if="rightPanelCollapsed"
    />
    <template v-else>
      <ul
        v-if="fileList.length"
        class="list-unstyled append-bottom-0"
      >
        <li
          v-for="file in fileList"
          :key="file.key"
        >
          <list-item
            :file="file"
          />
        </li>
      </ul>
    </template>
  </div>
</template>
