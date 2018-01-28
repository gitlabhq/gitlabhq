export default {
  small: { // Covers both xs and sm screen sizes
    margin: {
      top: 40,
      right: 40,
      bottom: 50,
      left: 40,
    },
    legends: {
      width: 15,
      height: 3,
      offsetX: 20,
      offsetY: 32,
    },
    backgroundLegend: {
      width: 30,
      height: 50,
    },
    axisLabelLineOffset: -20,
  },
  large: { // This covers both md and lg screen sizes
    margin: {
      top: 80,
      right: 80,
      bottom: 100,
      left: 80,
    },
    legends: {
      width: 15,
      height: 3,
      offsetX: 20,
      offsetY: 34,
    },
    backgroundLegend: {
      width: 30,
      height: 150,
    },
    axisLabelLineOffset: 20,
  },
  xTicks: 8,
  yTicks: 3,
};
