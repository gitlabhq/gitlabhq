import { shallowMount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import DetailRow from '~/ml/experiment_tracking/routes/candidates/show/components/candidate_detail_row.vue';

describe('CandidateDetailRow', () => {
  const SECTION_LABEL_CELL = 0;
  const ROW_LABEL_CELL = 1;
  const ROW_VALUE_CELL = 2;

  let wrapper;

  const createWrapper = (href = '') => {
    wrapper = shallowMount(DetailRow, {
      propsData: { sectionLabel: 'Section', label: 'Item', text: 'Text', href },
    });
  };

  const findCellAt = (index) => wrapper.findAll('td').at(index);
  const findLink = () => findCellAt(ROW_VALUE_CELL).findComponent(GlLink);

  beforeEach(() => createWrapper());

  it('renders section label', () => {
    expect(findCellAt(SECTION_LABEL_CELL).text()).toBe('Section');
  });

  it('renders row label', () => {
    expect(findCellAt(ROW_LABEL_CELL).text()).toBe('Item');
  });

  describe('No href', () => {
    it('Renders text', () => {
      expect(findCellAt(ROW_VALUE_CELL).text()).toBe('Text');
    });

    it('Does not render as link', () => {
      expect(findLink().exists()).toBe(false);
    });
  });

  describe('With href', () => {
    beforeEach(() => createWrapper('LINK'));

    it('Renders link', () => {
      expect(findLink().attributes().href).toBe('LINK');
      expect(findLink().text()).toBe('Text');
    });
  });
});
