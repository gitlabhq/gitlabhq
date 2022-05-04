<script>
import { GlPopover, GlOutsideDirective as Outside } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { FILE_TREE_POPOVER_DISMISSED_KEY } from '../../constants';

export default {
  name: 'PipelineEditorFileTreePopover',
  directives: { Outside },
  i18n: {
    description: s__(
      'pipelineEditorWalkthrough|You can use the file tree to view your pipeline configuration files.',
    ),
    learnMore: __('Learn more'),
  },
  components: {
    GlPopover,
  },
  data() {
    return {
      showPopover: false,
    };
  },
  mounted() {
    this.showPopover = localStorage.getItem(FILE_TREE_POPOVER_DISMISSED_KEY) !== 'true';
  },
  methods: {
    closePopover() {
      this.showPopover = false;
    },
    dismissPermanently() {
      this.closePopover();
      localStorage.setItem(FILE_TREE_POPOVER_DISMISSED_KEY, 'true');
    },
  },
};
</script>

<template>
  <gl-popover
    v-if="showPopover"
    show
    show-close-button
    target="file-tree-toggle"
    triggers="manual"
    placement="right"
    data-qa-selector="file_tree_popover"
    @close-button-clicked="dismissPermanently"
  >
    <div v-outside="closePopover" class="gl-display-flex gl-flex-direction-column">
      <p class="gl-font-base">{{ $options.i18n.description }}</p>
    </div>
  </gl-popover>
</template>
