export default {
  methods: {
    saveData(resp) {
      const headers = resp.headers;
      return resp.json().then((response) => {
        this.isLoading = false;

        this.store.storeAvailableCount(response.available_count);
        this.store.storeStoppedCount(response.stopped_count);
        this.store.storeEnvironments(response.environments);
        this.store.setPagination(headers);
      });
    },
  },
};
