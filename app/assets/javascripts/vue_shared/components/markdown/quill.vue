<script>
  import Quill from 'Quill';

  export default {
    props: {
      placeholder: {
        type: String,
        default: 'type something great'
      },
      toolbar: {
        type: Array,
        default: [['bold', 'italic', 'blockquote', 'code', 'list']]
      }
    },
    mounted() {
      let customToolbar = this.$slots["custom-toolbar"];
      let customToolbarHTML = customToolbar ? customToolbar[0].elm : false;
      let quillCustomToolbarId = 'custom-quilljs-toolbar'
      if(customToolbarHTML) {
        customToolbarHTML.id = quillCustomToolbarId;
      }
      let quill = new Quill(this.$el, {
        theme: 'snow',
        placeholder: this.placeholder,
        modules: {
          toolbar: this.toolbar,
        }
      });
      
      quill.on('text-change', (delta, oldDelta, source) => {
        let html = quill.root.innerHTML;
        this.$emit('change', html, delta, oldDelta, source);
      });
    }
  }  
</script>
<template>
<div>
  <slot name="content"></slot>
</div>
</template>