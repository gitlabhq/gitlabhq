export default {
  methods: {
    lineCssClass(line) {
      return {
        head: line.isHead,
        origin: line.isOrigin,
        match: line.hasMatch,
        selected: line.isSelected,
        unselected: line.isUnselected,
      };
    },
  },
};
