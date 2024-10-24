import { GlLoadingIcon, GlTable, GlButton } from '@gitlab/ui';
import { getAllByRole } from '@testing-library/dom';
import { shallowMount, mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import Papa from 'papaparse';
import CsvViewer from '~/blob/csv/csv_viewer.vue';
import PapaParseAlert from '~/blob/components/papa_parse_alert.vue';
import { MAX_ROWS_TO_RENDER } from '~/blob/csv/constants';

const validCsv = 'one,two,three';
const brokenCsv = '{\n "json": 1,\n "key": [1, 2, 3]\n}';

describe('app/assets/javascripts/blob/csv/csv_viewer.vue', () => {
  let wrapper;

  const createComponent = ({
    csv = validCsv,
    remoteFile = false,
    mountFunction = shallowMount,
  } = {}) => {
    wrapper = mountFunction(CsvViewer, {
      propsData: {
        csv,
        remoteFile,
      },
    });
  };

  const findCsvTable = () => wrapper.findComponent(GlTable);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAlert = () => wrapper.findComponent(PapaParseAlert);
  const findSwitchToRawViewBtn = () => wrapper.findComponent(GlButton);
  const findLargeCsvText = () => wrapper.find('[data-testid="large-csv-text"]');

  it('should render loading spinner', () => {
    createComponent();

    expect(findLoadingIcon().props()).toMatchObject({
      size: 'lg',
    });
  });

  describe('when the CSV contains errors', () => {
    it('should render alert with correct props', async () => {
      createComponent({ csv: brokenCsv });
      await nextTick();

      expect(findAlert().props()).toMatchObject({
        papaParseErrors: [{ code: 'UndetectableDelimiter' }],
      });
    });
  });

  describe('when the CSV contains no errors', () => {
    it('should not render alert', async () => {
      createComponent();
      await nextTick();

      expect(findAlert().exists()).toBe(false);
    });

    it('renders the CSV table with the correct attributes', async () => {
      createComponent();
      await nextTick();

      expect(findCsvTable().attributes()).toMatchObject({
        'empty-text': 'No CSV data to display.',
        items: validCsv,
      });
    });

    it('renders the CSV table with the correct content', async () => {
      createComponent({ mountFunction: mount });
      await nextTick();

      expect(getAllByRole(wrapper.element, 'row', { name: /One/i })).toHaveLength(1);
      expect(getAllByRole(wrapper.element, 'row', { name: /Two/i })).toHaveLength(1);
      expect(getAllByRole(wrapper.element, 'row', { name: /Three/i })).toHaveLength(1);
    });
  });

  describe('when the CSV is larger than 2000 lines', () => {
    beforeEach(async () => {
      const largeCsv = validCsv.repeat(3000);
      jest.spyOn(Papa, 'parse').mockImplementation(() => {
        return { data: largeCsv.split(','), errors: [] };
      });
      createComponent({ csv: largeCsv });
      await nextTick();
    });
    it('renders not more than max rows value', () => {
      expect(Papa.parse).toHaveBeenCalledTimes(1);
      expect(wrapper.vm.items).toHaveLength(MAX_ROWS_TO_RENDER);
    });
    it('renders large csv text', () => {
      expect(findLargeCsvText().text()).toBe(
        'The file is too large to render all the rows. To see the entire file, switch to the raw view.',
      );
    });
    it('renders button with link to raw view', () => {
      const url = 'http://test.host/?plain=1';
      expect(findSwitchToRawViewBtn().text()).toBe('View raw data');
      expect(findSwitchToRawViewBtn().attributes('href')).toBe(url);
    });
  });

  describe('when csv prop is path and indicates a remote file', () => {
    it('should render call parse with download flag true', async () => {
      const path = 'path/to/remote/file.csv';
      jest.spyOn(Papa, 'parse').mockImplementation((_, { complete }) => {
        complete({ data: validCsv.split(','), errors: [] });
      });

      createComponent({ csv: path, remoteFile: true });
      expect(Papa.parse).toHaveBeenCalledWith(path, {
        download: true,
        skipEmptyLines: true,
        complete: expect.any(Function),
      });
      await nextTick();
      expect(wrapper.vm.items).toEqual(validCsv.split(','));
    });
  });
});
