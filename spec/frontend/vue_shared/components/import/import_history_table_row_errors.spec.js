import { GlAlert, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import ImportHistoryTableRowErrors from '~/vue_shared/components/import/import_history_table_row_errors.vue';
import { apiItems } from './history_mock_data';

describe('ImportHistoryTableRowStats component', () => {
  let wrapper;

  const findErrors = () => wrapper.findAllByTestId('import-history-table-row-error');
  const findAlerts = () => wrapper.findAllComponents(GlAlert);
  const findLinks = () => wrapper.findAllComponents(GlLink);
  const findRaws = () => wrapper.findAllByTestId('import-history-table-row-error-raw');

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(ImportHistoryTableRowErrors, {
      propsData: {
        item: apiItems[1],
        ...props,
      },
    });
  };

  it('does not render any errors if there are no failures', () => {
    createComponent({ item: apiItems[0] });
    expect(findErrors().length).toEqual(0);
  });

  it('renders an error for each failure in the item data', () => {
    createComponent();
    expect(findErrors().length).toEqual(apiItems[1].failures.length);
  });

  describe('alert', () => {
    beforeEach(() => {
      createComponent();
    });
    it('renders GlAlert', () => {
      expect(findAlerts().length).toEqual(apiItems[1].failures.length);
    });
    it('renders GlLink', () => {
      expect(findLinks().length).toEqual(apiItems[1].failures.length);
    });
    it('uses custom link_text if provided', () => {
      createComponent({ item: apiItems[3] });
      expect(findLinks().at(0).element.innerText).toEqual(apiItems[3].failures[0].link_text);
    });
  });

  it('renders raw if it exists', () => {
    createComponent({ item: apiItems[3] });
    expect(findRaws().length).toEqual(1);
  });
});
