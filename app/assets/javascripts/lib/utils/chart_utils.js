const commonTooltips = () => ({
  mode: 'x',
  intersect: false,
});

const adjustedFontScale = () => ({
  fontSize: 8,
});

const yAxesConfig = (shouldAdjustFontSize = false) => ({
  yAxes: [
    {
      ticks: {
        beginAtZero: true,
        ...(shouldAdjustFontSize ? adjustedFontScale() : {}),
      },
    },
  ],
});

const xAxesConfig = (shouldAdjustFontSize = false) => ({
  xAxes: [
    {
      ticks: {
        ...(shouldAdjustFontSize ? adjustedFontScale() : {}),
      },
    },
  ],
});

const commonChartOptions = () => ({
  responsive: true,
  maintainAspectRatio: false,
  legend: false,
});

export const barChartOptions = shouldAdjustFontSize => ({
  ...commonChartOptions(),
  scales: {
    ...yAxesConfig(shouldAdjustFontSize),
    ...xAxesConfig(shouldAdjustFontSize),
  },
  tooltips: {
    ...commonTooltips(),
    displayColors: false,
    callbacks: {
      title() {
        return '';
      },
      label({ xLabel, yLabel }) {
        return `${xLabel}: ${yLabel}`;
      },
    },
  },
});

export const pieChartOptions = commonChartOptions;

export const lineChartOptions = ({ width, numberOfPoints, shouldAdjustFontSize }) => ({
  ...commonChartOptions(),
  scales: {
    ...yAxesConfig(shouldAdjustFontSize),
    ...xAxesConfig(shouldAdjustFontSize),
  },
  elements: {
    point: {
      hitRadius: width / (numberOfPoints * 2),
    },
  },
  tooltips: {
    ...commonTooltips(),
    caretSize: 0,
    multiKeyBackground: 'rgba(0,0,0,0)',
    callbacks: {
      labelColor({ datasetIndex }, { config }) {
        return {
          backgroundColor: config.data.datasets[datasetIndex].backgroundColor,
          borderColor: 'rgba(0,0,0,0)',
        };
      },
    },
  },
});
