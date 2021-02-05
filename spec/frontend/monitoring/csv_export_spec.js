import { graphDataToCsv } from '~/monitoring/csv_export';
import { timeSeriesGraphData } from './graph_data';

describe('monitoring export_csv', () => {
  describe('graphDataToCsv', () => {
    const expectCsvToMatchLines = (csv, lines) => expect(`${lines.join('\r\n')}\r\n`).toEqual(csv);

    it('should return a csv with 0 metrics', () => {
      const data = timeSeriesGraphData({}, { metricCount: 0 });

      expect(graphDataToCsv(data)).toEqual('');
    });

    it('should return a csv with 1 metric with no data', () => {
      const data = timeSeriesGraphData({}, { metricCount: 1 });

      // When state is NO_DATA, result is null
      data.metrics[0].result = null;

      expect(graphDataToCsv(data)).toEqual('');
    });

    it('should return a csv with 1 metric', () => {
      const data = timeSeriesGraphData({}, { metricCount: 1 });

      expectCsvToMatchLines(graphDataToCsv(data), [
        `timestamp,"Y Axis > Metric 1"`,
        '2015-07-01T20:10:50.000Z,1',
        '2015-07-01T20:12:50.000Z,2',
        '2015-07-01T20:14:50.000Z,3',
      ]);
    });

    it('should return a csv with multiple metrics and one with no data', () => {
      const data = timeSeriesGraphData({}, { metricCount: 2 });

      // When state is NO_DATA, result is null
      data.metrics[0].result = null;

      expectCsvToMatchLines(graphDataToCsv(data), [
        `timestamp,"Y Axis > Metric 2"`,
        '2015-07-01T20:10:50.000Z,1',
        '2015-07-01T20:12:50.000Z,2',
        '2015-07-01T20:14:50.000Z,3',
      ]);
    });

    it('should return a csv when not all metrics have the same timestamps', () => {
      const data = timeSeriesGraphData({}, { metricCount: 3 });

      // Add an "odd" timestamp that is not in the dataset
      Object.assign(data.metrics[2].result[0], {
        value: ['2016-01-01T00:00:00.000Z', 9],
        values: [['2016-01-01T00:00:00.000Z', 9]],
      });

      expectCsvToMatchLines(graphDataToCsv(data), [
        `timestamp,"Y Axis > Metric 1","Y Axis > Metric 2","Y Axis > Metric 3"`,
        '2015-07-01T20:10:50.000Z,1,1,',
        '2015-07-01T20:12:50.000Z,2,2,',
        '2015-07-01T20:14:50.000Z,3,3,',
        '2016-01-01T00:00:00.000Z,,,9',
      ]);
    });

    it('should escape double quotes in metric labels with two double quotes ("")', () => {
      const data = timeSeriesGraphData({}, { metricCount: 1 });

      data.metrics[0].label = 'My "quoted" metric';

      expectCsvToMatchLines(graphDataToCsv(data), [
        `timestamp,"Y Axis > My ""quoted"" metric"`,
        '2015-07-01T20:10:50.000Z,1',
        '2015-07-01T20:12:50.000Z,2',
        '2015-07-01T20:14:50.000Z,3',
      ]);
    });

    it('should return a csv with multiple metrics', () => {
      const data = timeSeriesGraphData({}, { metricCount: 3 });

      expectCsvToMatchLines(graphDataToCsv(data), [
        `timestamp,"Y Axis > Metric 1","Y Axis > Metric 2","Y Axis > Metric 3"`,
        '2015-07-01T20:10:50.000Z,1,1,1',
        '2015-07-01T20:12:50.000Z,2,2,2',
        '2015-07-01T20:14:50.000Z,3,3,3',
      ]);
    });

    it('should return a csv with 1 metric and multiple series with labels', () => {
      const data = timeSeriesGraphData({}, { isMultiSeries: true });

      expectCsvToMatchLines(graphDataToCsv(data), [
        `timestamp,"Y Axis > Metric 1","Y Axis > Metric 1"`,
        '2015-07-01T20:10:50.000Z,1,4',
        '2015-07-01T20:12:50.000Z,2,5',
        '2015-07-01T20:14:50.000Z,3,6',
      ]);
    });

    it('should return a csv with 1 metric and multiple series', () => {
      const data = timeSeriesGraphData({}, { isMultiSeries: true, withLabels: false });

      expectCsvToMatchLines(graphDataToCsv(data), [
        `timestamp,"Y Axis > __name__: up, job: prometheus, instance: localhost:9090","Y Axis > __name__: up, job: node, instance: localhost:9091"`,
        '2015-07-01T20:10:50.000Z,1,4',
        '2015-07-01T20:12:50.000Z,2,5',
        '2015-07-01T20:14:50.000Z,3,6',
      ]);
    });

    it('should return a csv with multiple metrics and multiple series', () => {
      const data = timeSeriesGraphData(
        {},
        { metricCount: 3, isMultiSeries: true, withLabels: false },
      );

      expectCsvToMatchLines(graphDataToCsv(data), [
        `timestamp,"Y Axis > __name__: up, job: prometheus, instance: localhost:9090","Y Axis > __name__: up, job: node, instance: localhost:9091","Y Axis > __name__: up, job: prometheus, instance: localhost:9090","Y Axis > __name__: up, job: node, instance: localhost:9091","Y Axis > __name__: up, job: prometheus, instance: localhost:9090","Y Axis > __name__: up, job: node, instance: localhost:9091"`,
        '2015-07-01T20:10:50.000Z,1,4,1,4,1,4',
        '2015-07-01T20:12:50.000Z,2,5,2,5,2,5',
        '2015-07-01T20:14:50.000Z,3,6,3,6,3,6',
      ]);
    });
  });
});
