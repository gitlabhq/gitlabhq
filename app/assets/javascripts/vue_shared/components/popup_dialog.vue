<script>
const PopupDialog = {
  name: 'popup-dialog',

  props: {
    title: String,
    body: String,
    kind: {
      type: String,
      default: 'primary',
    },
    closeButtonLabel: {
      type: String,
      default: 'Cancel',
    },
    primaryButtonLabel: {
      type: String,
      default: 'Save changes',
    },
  },

  computed: {
    typeOfClass() {
      const className = `btn-${this.kind}`;
      const returnObj = {};
      returnObj[className] = true;
      return returnObj;
    },
  },

  methods: {
    close() {
      this.$emit('toggle', false);
    },

    yesClick() {
      this.$emit('submit', true);
    },

    noClick() {
      this.$emit('submit', false);
    },
  },
};

export default PopupDialog;
</script>
<template>
<div class="modal popup-dialog" tabindex="-1" role="dialog">
  <div class="modal-dialog" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button" class="close" @click="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
        <h4 class="modal-title">{{this.title}}</h4>
      </div>
      <div class="modal-body">
        <p>{{this.body}}</p>
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-default" data-dismiss="modal" @click="noClick">{{closeButtonLabel}}</button>
        <button type="button" class="btn" :class="typeOfClass" @click="yesClick">{{primaryButtonLabel}}</button>
      </div>
    </div>
  </div>
</div>
</template>
