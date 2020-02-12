export default {
  computed: {
    seriesData() {
      const data = Object.keys(this.chartData).reduce((acc, key) => {
        acc.push([key, this.chartData[key]]);
        return acc;
      }, []);
      return { full: data };
    },
  },
};
