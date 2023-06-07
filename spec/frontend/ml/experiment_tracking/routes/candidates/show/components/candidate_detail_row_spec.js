import { shallowMount } from '@vue/test-utils';
import DetailRow from '~/ml/experiment_tracking/routes/candidates/show/components/candidate_detail_row.vue';

describe('CandidateDetailRow', () => {
  const SECTION_LABEL_CELL = 0;
  const ROW_LABEL_CELL = 1;
  const ROW_VALUE_CELL = 2;

  let wrapper;

  const createWrapper = ({ slots = {} } = {}) => {
    wrapper = shallowMount(DetailRow, {
      propsData: { sectionLabel: 'Section', label: 'Item' },
      slots,
    });
  };

  const findCellAt = (index) => wrapper.findAll('td').at(index);

  beforeEach(() => createWrapper());

  it('renders section label', () => {
    expect(findCellAt(SECTION_LABEL_CELL).text()).toBe('Section');
  });

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
