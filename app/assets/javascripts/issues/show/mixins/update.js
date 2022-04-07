import eventHub from '../event_hub';

export default {
  methods: {
    updateIssuable() {
      eventHub.$emit('update.issuable');
    },
  },
};
