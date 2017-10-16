import eventHub from '../event_hub';

export default {
  methods: {
    updateIssuable() {
      this.formState.updateLoading = true;
      eventHub.$emit('update.issuable');
    },
  },
};
