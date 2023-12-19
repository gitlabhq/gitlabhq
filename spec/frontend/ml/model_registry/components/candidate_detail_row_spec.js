import { shallowMount } from '@vue/test-utils';
import DetailRow from '~/ml/model_registry/components/candidate_detail_row.vue';

describe('CandidateDetailRow', () => {
  const ROW_LABEL_CELL = 0;
  const ROW_VALUE_CELL = 1;

  let wrapper;

  const createWrapper = ({ slots = {} } = {}) => {
    wrapper = shallowMount(DetailRow, {
      propsData: { label: 'Item' },
      slots,
    });
  };

  const findCellAt = (index) => wrapper.findAll('td').at(index);

  beforeEach(() => createWrapper());

  it('renders row label', () => {
    expect(findCellAt(ROW_LABEL_CELL).text()).toBe('Item');
  });

  it('renders nothing on item cell', () => {
    expect(findCellAt(ROW_VALUE_CELL).text()).toBe('');
  });

  describe('With slot', () => {
    beforeEach(() => createWrapper({ slots: { default: 'Some content' } }));

    it('Renders slot', () => {
      expect(findCellAt(ROW_VALUE_CELL).text()).toBe('Some content');
    });
  });
});
