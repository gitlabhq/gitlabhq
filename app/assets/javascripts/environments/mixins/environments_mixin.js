export default {
  methods: {
    saveData(resp) {
      const response = {
        headers: resp.headers,
        body: resp.json(),
      };

      this.isLoading = false;

      this.store.storeAvailableCount(response.body.available_count);
      this.store.storeStoppedCount(response.body.stopped_count);
      this.store.storeEnvironments(response.body.environments);
      this.store.setPagination(response.headers);
    },
  },
};
